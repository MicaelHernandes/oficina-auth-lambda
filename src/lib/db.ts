// Acesso ao PostgreSQL (RDS). Pool reaproveitado entre invocações (warm start).
import { Pool } from "pg";

export interface Customer {
  id: number;
  name: string;
}

let pool: Pool | undefined;

function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT ?? 5432),
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      max: 1, // Lambda: 1 conexão por container é suficiente
      idleTimeoutMillis: 30_000,
      connectionTimeoutMillis: 5_000,
      ssl: { rejectUnauthorized: false }, // RDS exige TLS
    });
  }
  return pool;
}

/**
 * Busca um cliente ATIVO pelo documento (CPF/CNPJ, só dígitos).
 * Cliente ativo = não deletado (soft delete). Retorna null se não existir.
 *
 * IMPORTANTE: a coluna é `document`, não `cpf`; "inativo" = deleted_at != null.
 */
export async function findActiveCustomerByDocument(
  document: string,
): Promise<Customer | null> {
  const result = await getPool().query<Customer>(
    "SELECT id, name FROM customers WHERE document = $1 AND deleted_at IS NULL LIMIT 1",
    [document],
  );
  return result.rows[0] ?? null;
}
