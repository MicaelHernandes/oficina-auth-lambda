# ---------------------------------------------------------------------------
# Versões e backend de estado (repo 1 — Lambda de auth + API Gateway).
# Apply roda exclusivamente no GitHub Actions (branch master).
# ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket         = "oficina-tfstate-909314263457"
    key            = "oficina-auth-lambda/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oficina-tflock"
    encrypt        = true
  }
}
