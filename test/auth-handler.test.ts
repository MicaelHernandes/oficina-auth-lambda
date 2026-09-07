import { describe, it, expect, vi, beforeEach } from "vitest";
import type { APIGatewayProxyEventV2 } from "aws-lambda";

// DB mockado — não conecta no Postgres real.
vi.mock("../src/lib/db", () => ({
  findActiveCustomerByDocument: vi.fn(),
}));

import { handler } from "../src/auth/handler";
import { findActiveCustomerByDocument } from "../src/lib/db";
import { verifyToken } from "../src/lib/jwt";

const mockFind = vi.mocked(findActiveCustomerByDocument);

function event(body: unknown): APIGatewayProxyEventV2 {
  return { body: JSON.stringify(body) } as APIGatewayProxyEventV2;
}

function parse(result: any) {
  return { status: result.statusCode, body: JSON.parse(result.body) };
}

beforeEach(() => {
  process.env.JWT_SECRET = "test-secret";
  mockFind.mockReset();
});

describe("auth handler", () => {
  it("400 para CPF inválido", async () => {
    const res = parse(await handler(event({ cpf: "111.111.111-11" })));
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("invalid_cpf");
    expect(mockFind).not.toHaveBeenCalled();
  });

  it("400 para corpo sem cpf", async () => {
    const res = parse(await handler(event({})));
    expect(res.status).toBe(400);
  });

  it("401 para cliente inexistente/inativo", async () => {
    mockFind.mockResolvedValue(null);
    const res = parse(await handler(event({ cpf: "529.982.247-25" })));
    expect(res.status).toBe(401);
    expect(res.body.error).toBe("customer_not_found");
  });

  it("200 com JWT válido para cliente ativo", async () => {
    mockFind.mockResolvedValue({ id: 7, name: "Fulano" });
    const res = parse(await handler(event({ cpf: "529.982.247-25" })));
    expect(res.status).toBe(200);
    expect(res.body.token_type).toBe("Bearer");
    expect(mockFind).toHaveBeenCalledWith("52998224725");

    const claims = verifyToken(res.body.token, "test-secret");
    expect(claims.sub).toBe("7");
    expect(claims.cpf).toBe("52998224725");
  });

  it("consulta usando o documento normalizado (só dígitos)", async () => {
    mockFind.mockResolvedValue({ id: 1, name: "X" });
    await handler(event({ cpf: "529.982.247-25" }));
    expect(mockFind).toHaveBeenCalledWith("52998224725");
  });
});
