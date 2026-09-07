locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
    Repo      = "oficina-auth-lambda"
  }

  api_host = "api.${var.domain}"

  # Credenciais do RDS lidas do secret do repo 3 (injetadas como env var).
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}
