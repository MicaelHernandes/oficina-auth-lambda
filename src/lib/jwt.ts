// Geração e validação de JWT HS256 compartilhado com o app Laravel.
import jwt from "jsonwebtoken";

export interface AuthClaims {
  sub: string; // customer_id
  cpf: string; // document (só dígitos)
}

export interface VerifiedClaims extends AuthClaims {
  iss: string;
  iat: number;
  exp: number;
}

const ISSUER = process.env.JWT_ISSUER ?? "oficina-auth";
const TTL_SECONDS = Number(process.env.JWT_TTL ?? 900); // 15 min

/** Assina um JWT HS256 com sub/cpf, exp e iss. */
export function signToken(claims: AuthClaims, secret: string): string {
  return jwt.sign({ cpf: claims.cpf }, secret, {
    algorithm: "HS256",
    subject: claims.sub,
    issuer: ISSUER,
    expiresIn: TTL_SECONDS,
  });
}

/** Valida um JWT HS256; lança em token inválido/expirado. */
export function verifyToken(token: string, secret: string): VerifiedClaims {
  const decoded = jwt.verify(token, secret, {
    algorithms: ["HS256"],
    issuer: ISSUER,
  });
  return decoded as VerifiedClaims;
}

export const jwtConfig = { issuer: ISSUER, ttlSeconds: TTL_SECONDS };
