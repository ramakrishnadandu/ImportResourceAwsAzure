terraform {
  backend "s3" {
    bucket       = "tfbackendrkd-us-east-1"
    key          = "terraform/iam-role/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}