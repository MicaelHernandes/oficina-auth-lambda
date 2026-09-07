// Função Serverless de autenticação por CPF.
// Recebe { "cpf": "..." }, valida, consulta o cliente no RDS e devolve um JWT.
import type {
  APIGatewayProxyEventV2,
  APIGatewayProxyResultV2,
} from "aws-lambda";
import { isValidCpf, normalizeCpf } from "../lib/cpf";
import { signToken, jwtConfig } from "../lib/jwt";
import { findActiveCustomerByDocument } from "../lib/db";

function json(statusCode: number, body: unknown): APIGatewayProxyResultV2 {
  return {
    statusCode,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}

export async function handler(
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> {
  let cpfRaw: string | undefined;
  try {
    const parsed = JSON.parse(event.body ?? "{}");
    cpfRaw = parsed.cpf;
  } catch {
    return json(400, { error: "invalid_body", message: "Corpo JSON inválido." });
  }

  if (!cpfRaw || !isValidCpf(cpfRaw)) {
    return json(400, { error: "invalid_cpf", message: "CPF inválido." });
  }

  const document = normalizeCpf(cpfRaw);

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    return json(500, { error: "server_error", message: "JWT não configurado." });
  }

  let customer;
  try {
    customer = await findActiveCustomerByDocument(document);
  } catch (err) {
    console.error(JSON.stringify({ level: "error", msg: "db_error", err: String(err) }));
    return json(500, { error: "server_error", message: "Falha ao consultar o cliente." });
  }

  if (!customer) {
    return json(401, {
      error: "customer_not_found",
      message: "Cliente inexistente ou inativo.",
    });
  }

  const token = signToken({ sub: String(customer.id), cpf: document }, secret);

  return json(200, {
    token,
    token_type: "Bearer",
    expires_in: jwtConfig.ttlSeconds,
    customer: { id: customer.id, name: customer.name },
  });
}
