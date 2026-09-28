variable "aws_region" {
  description = "AWS region for the provider. IAM is global, but the provider still requires a region."
  type        = string
  default     = "us-east-1"
}

variable "bucket_arn" {
  description = "ARN of the existing S3 bucket this role may access, for example arn:aws:s3:::my-bucket."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:s3:::[^/]+$", var.bucket_arn))
    error_message = "bucket_arn must be an S3 bucket ARN without an object path."
  }
}

variable "role_name" {
  description = "Name of the EC2 IAM role."
  type        = string
  default     = "Ec2S3AccessRole"
}

variable "policy_name" {
  description = "Name of the inline role policy."
  type        = string
  default     = "Ec2S3AccessPolicy"
}

variable "instance_profile_name" {
  description = "Name of the EC2 instance profile."
  type        = string
  default     = "Ec2S3AccessRole"
}
