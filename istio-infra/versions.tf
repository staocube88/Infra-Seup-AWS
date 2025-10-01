# ───────────────────────────────
# Terraform and Provider Versions
# ───────────────────────────────

terraform {
  required_version = ">= 1.3.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  # Backend configuration
  backend "s3" {
    # Configured via terraform init or environment variables
  }
}
