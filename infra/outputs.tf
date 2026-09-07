output "api_endpoint" {
  description = "Endpoint padrão do API Gateway (execute-api)."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_url" {
  description = "URL pública da API via custom domain."
  value       = "https://${local.api_host}"
}

output "auth_function_name" {
  description = "Nome da Lambda de auth."
  value       = aws_lambda_function.auth.function_name
}

output "authorizer_function_name" {
  description = "Nome do Lambda Authorizer."
  value       = aws_lambda_function.authorizer.function_name
}

output "jwt_secret_arn" {
  description = "ARN do secret da JWT_SECRET (o app Laravel lê daqui)."
  value       = aws_secretsmanager_secret.jwt.arn
}
