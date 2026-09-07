# ---------------------------------------------------------------------------
# Autenticação serverless: Lambda de auth por CPF + Lambda Authorizer,
# expostas por um API Gateway HTTP API com custom domain api.codefive.com.br.
# ---------------------------------------------------------------------------

# === JWT secret (compartilhado com o app Laravel) =========================
resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "jwt" {
  name = "/oficina/jwt/secret"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id     = aws_secretsmanager_secret.jwt.id
  secret_string = random_password.jwt.result
}

resource "aws_ssm_parameter" "jwt_secret_arn" {
  name  = "/oficina/jwt/secret_arn"
  type  = "String"
  value = aws_secretsmanager_secret.jwt.arn
  tags  = local.tags
}

# === Rede: SG da Lambda + liberação no RDS ================================
resource "aws_security_group" "lambda" {
  name        = "${var.project}-auth-lambda"
  description = "SG da Lambda de auth (egress para o RDS)"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
  tags        = local.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Egress liberado (acesso ao RDS na subnet privada)"
  }
}

# Libera 5432 no SG do RDS (repo 3) a partir do SG da Lambda.
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.aws_ssm_parameter.db_security_group_id.value
  source_security_group_id = aws_security_group.lambda.id
  description              = "PostgreSQL a partir da Lambda de auth"
}

# === IAM da Lambda ========================================================
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-auth-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# === Empacotamento (esbuild gerou dist/auth e dist/authorizer) ============
data "archive_file" "auth" {
  type        = "zip"
  source_dir  = "${path.module}/../dist/auth"
  output_path = "${path.module}/build/auth.zip"
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/../dist/authorizer"
  output_path = "${path.module}/build/authorizer.zip"
}

# === Lambdas ==============================================================
# Auth: dentro da VPC (alcança o RDS). Credenciais injetadas como env var.
resource "aws_lambda_function" "auth" {
  function_name    = "${var.project}-auth"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.auth.output_path
  source_code_hash = data.archive_file.auth.output_base64sha256
  timeout          = 15
  memory_size      = 256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST     = data.aws_ssm_parameter.db_endpoint.value
      DB_PORT     = data.aws_ssm_parameter.db_port.value
      DB_NAME     = data.aws_ssm_parameter.db_name.value
      DB_USER     = local.db_creds.username
      DB_PASSWORD = local.db_creds.password
      JWT_SECRET  = random_password.jwt.result
      JWT_ISSUER  = var.jwt_issuer
      JWT_TTL     = tostring(var.jwt_ttl_seconds)
    }
  }

  tags = local.tags
}

# Authorizer: fora da VPC (só valida JWT, sem acesso a banco).
resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.project}-authorizer"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      JWT_SECRET = random_password.jwt.result
      JWT_ISSUER = var.jwt_issuer
    }
  }

  tags = local.tags
}

# === API Gateway HTTP API =================================================
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"
  tags          = local.tags
}

# POST /auth -> Lambda de auth (sem authorizer).
resource "aws_apigatewayv2_integration" "auth" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

# ANY /{proxy+} -> backend (ALB), protegido pelo Lambda Authorizer.
resource "aws_apigatewayv2_integration" "proxy" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "${var.app_backend_url}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id                            = aws_apigatewayv2_api.this.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${var.project}-jwt-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  authorizer_result_ttl_in_seconds  = 0
}

resource "aws_apigatewayv2_route" "auth" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /auth"
  target    = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags

  default_route_settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

# Permissões para o API Gateway invocar as Lambdas.
resource "aws_lambda_permission" "auth" {
  statement_id  = "AllowAPIGWInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "AllowAPIGWInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.jwt.id}"
}

# === Custom domain api.codefive.com.br ====================================
resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = local.api_host

  domain_name_configuration {
    certificate_arn = data.aws_ssm_parameter.certificate_arn.value
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zone.this.id
  name    = local.api_host
  value   = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
  type    = "CNAME"
  ttl     = 300
  proxied = false
}
