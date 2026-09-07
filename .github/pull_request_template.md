## O que muda

<!-- Descreva a alteração na Lambda de auth / API Gateway. -->

## Tipo

- [ ] Código da Lambda (auth / authorizer)
- [ ] Terraform (API Gateway / Lambda / rede)
- [ ] Testes
- [ ] Documentação

## Checklist

- [ ] `npm test` verde
- [ ] `npm run typecheck` sem erros
- [ ] `npm run build` gera `dist/`
- [ ] `terraform fmt` + `validate` (em `infra/`) OK
- [ ] Revisei o `terraform plan` comentado pelo CI
- [ ] Nenhum segredo commitado (JWT_SECRET, token Cloudflare, senha do RDS)
- [ ] PR direcionado a `homolog` (ou de `homolog` para `master`)
