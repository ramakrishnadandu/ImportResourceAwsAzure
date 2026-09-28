terraform {
  required_version = ">= 1.10.0" # 1.10+ needed for S3 native state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial config: bucket and region are passed with -backend-config.
  # The bootstrap stack stores its own state in the bucket it creates.
  backend "s3" {
    key          = "bootstrap/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Stack     = "tf-backend-bootstrap"
      Repo      = "ImportResourceAwsAzure"
    }
  }
}
