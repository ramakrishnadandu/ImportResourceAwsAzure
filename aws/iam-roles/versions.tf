terraform {
  required_version = ">= 1.10.0" # for_each on import blocks needs 1.7+, use_lockfile needs 1.10+

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial config: bucket and region are passed with -backend-config
  # (see example.backend.hcl and the GitHub workflow).
  backend "s3" {
    key          = "iam-roles/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
