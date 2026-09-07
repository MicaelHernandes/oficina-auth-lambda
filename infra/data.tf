# ---------------------------------------------------------------------------
# Lê outputs dos repos 2 (rede + ACM) e 3 (banco) via SSM Parameter Store,
# além do secret do RDS (para injetar credenciais na Lambda como env var).
# ---------------------------------------------------------------------------

# --- Rede / ACM (repo 2) ---
data "aws_ssm_parameter" "vpc_id" {
  name = "/oficina/network/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/oficina/network/private_subnet_ids"
}

data "aws_ssm_parameter" "certificate_arn" {
  name = "/oficina/acm/certificate_arn"
}

# --- Banco (repo 3) ---
data "aws_ssm_parameter" "db_endpoint" {
  name = "/oficina/db/endpoint"
}

data "aws_ssm_parameter" "db_port" {
  name = "/oficina/db/port"
}

data "aws_ssm_parameter" "db_name" {
  name = "/oficina/db/name"
}

data "aws_ssm_parameter" "db_secret_arn" {
  name = "/oficina/db/secret_arn"
}

data "aws_ssm_parameter" "db_security_group_id" {
  name = "/oficina/db/security_group_id"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_ssm_parameter.db_secret_arn.value
}

# --- Cloudflare ---
data "cloudflare_zone" "this" {
  name = var.domain
}

locals {
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}
