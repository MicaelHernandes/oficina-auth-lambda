# Convenções — oficina-auth-lambda

Repositório 1 de 4 do Tech Challenge Fase 3. Autenticação serverless por CPF:
Lambda de auth (emite JWT HS256) + Lambda Authorizer + API Gateway HTTP API.

## Estrutura

- `src/` — TypeScript. `src/auth` (emite JWT), `src/authorizer` (valida JWT),
  `src/lib` (cpf, jwt, db). Build com esbuild para `dist/`.
- `test/` — Vitest (CPF, JWT, handler com DB mockado).
- `infra/` — Terraform (Lambdas, API Gateway, custom domain, secret, SG).

## Regras

- **`terraform apply` roda SÓ no GitHub Actions** (branch `master`). Localmente
  só `init`/`fmt`/`validate`/`plan`. O build (`npm run build`) precede o apply
  (o Terraform empacota `dist/`).
- Lê rede/ACM (repo 2) e banco (repo 3) via **SSM** (`/oficina/*`). Requer que
  os repos 2 e 3 já tenham sido aplicados (ordem 2 → 3 → 1 → 4).
- `JWT_SECRET` é criada aqui (`/oficina/jwt/secret`) e injetada como env var;
  o app Laravel (repo 4) lê o mesmo secret para validar os tokens.
- Credenciais do RDS injetadas como env var (lidas do secret do repo 3).

## Schema (auth)

A tabela `customers` usa a coluna **`document`** (CPF/CNPJ, só dígitos), não
`cpf`. Cliente ativo = `deleted_at IS NULL` (não há coluna `status`). A query
é `WHERE document = $1 AND deleted_at IS NULL`.
