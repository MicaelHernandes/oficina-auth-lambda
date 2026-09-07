// Lambda Authorizer (payload v2, simple response) para o API Gateway HTTP API.
// Valida o JWT do header Authorization: Bearer e devolve isAuthorized + contexto.
import type {
  APIGatewayRequestAuthorizerEventV2,
  APIGatewaySimpleAuthorizerWithContextResult,
} from "aws-lambda";
import { verifyToken } from "../lib/jwt";

interface AuthContext {
  customer_id: string;
  cpf: string;
}

const deny: APIGatewaySimpleAuthorizerWithContextResult<AuthContext> = {
  isAuthorized: false,
  context: { customer_id: "", cpf: "" },
};

export async function handler(
  event: APIGatewayRequestAuthorizerEventV2,
): Promise<APIGatewaySimpleAuthorizerWithContextResult<AuthContext>> {
  const header =
    event.headers?.authorization ?? event.headers?.Authorization ?? "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) return deny;

  const secret = process.env.JWT_SECRET;
  if (!secret) {
    console.error(JSON.stringify({ level: "error", msg: "jwt_secret_missing" }));
    return deny;
  }

  try {
    const claims = verifyToken(match[1], secret);
    return {
      isAuthorized: true,
      context: { customer_id: claims.sub, cpf: claims.cpf },
    };
  } catch {
    return deny;
  }
}
