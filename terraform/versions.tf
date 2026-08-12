terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.7"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Default: local backend.
  # For team usage swap to:
  #   backend "s3" { ... }   # or Terraform Cloud / HCP Terraform (free tier)
  backend "local" {
    path = "terraform.tfstate"
  }
}
