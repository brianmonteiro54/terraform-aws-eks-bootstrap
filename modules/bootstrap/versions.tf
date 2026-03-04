# =============================================================================
# Terraform and Provider Versions
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31"
    }
  }
  required_version = ">= 1.9.0"
}