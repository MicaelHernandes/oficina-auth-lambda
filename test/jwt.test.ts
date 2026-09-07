import { describe, it, expect } from "vitest";
import { signToken, verifyToken } from "../src/lib/jwt";

const SECRET = "test-secret-please-change";

describe("jwt HS256", () => {
  it("assina e valida com sub e cpf", () => {
    const token = signToken({ sub: "42", cpf: "52998224725" }, SECRET);
    const claims = verifyToken(token, SECRET);
    expect(claims.sub).toBe("42");
    expect(claims.cpf).toBe("52998224725");
    expect(claims.iss).toBe("oficina-auth");
    expect(claims.exp).toBeGreaterThan(claims.iat);
  });

  it("rejeita secret errada", () => {
    const token = signToken({ sub: "42", cpf: "52998224725" }, SECRET);
    expect(() => verifyToken(token, "outra-secret")).toThrow();
  });

  it("rejeita token adulterado", () => {
    const token = signToken({ sub: "42", cpf: "52998224725" }, SECRET);
    expect(() => verifyToken(token + "x", SECRET)).toThrow();
  });
});
