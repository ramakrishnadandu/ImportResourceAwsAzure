variable "aws_region" {
  description = "Region for the Terraform state bucket."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name of the S3 bucket that holds Terraform state."
  type        = string
}

variable "import_existing_bucket" {
  description = "Set to true when the bucket already exists in AWS but not in Terraform state, so it is imported instead of created."
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep old (noncurrent) state file versions."
  type        = number
  default     = 90
}
