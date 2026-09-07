variable "region" {
  description = "Região AWS."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefixo do projeto."
  type        = string
  default     = "oficina"
}

variable "domain" {
  description = "Domínio raiz gerenciado na Cloudflare."
  type        = string
  default     = "codefive.com.br"
}

variable "cloudflare_api_token" {
  description = "Token de API da Cloudflare (secret CLOUDFLARE_API_TOKEN)."
  type        = string
  sensitive   = true
}

variable "jwt_ttl_seconds" {
  description = "Validade do JWT em segundos."
  type        = number
  default     = 900
}

variable "jwt_issuer" {
  description = "Issuer do JWT."
  type        = string
  default     = "oficina-auth"
}

variable "app_backend_url" {
  description = "URL do backend (ALB) para o proxy do API Gateway."
  type        = string
  default     = "https://app.codefive.com.br"
}
