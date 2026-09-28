variable "aws_region" {
  description = "AWS region for the provider (IAM is global, but the provider still needs one)."
  type        = string
  default     = "us-east-1"
}

variable "existing_roles" {
  description = <<-EOT
    IAM roles that already exist in AWS and should be brought under Terraform.
    Map key = role name. Values must match the live role, otherwise the first plan
    shows an in-place update after the import. Use scripts/discover-roles.sh to
    generate this from AWS.
  EOT
  type = map(object({
    path                    = optional(string, "/")
    description             = optional(string)
    max_session_duration    = optional(number, 3600)
    permissions_boundary    = optional(string)
    assume_role_policy_file = string # relative to this folder, e.g. policies/my-role-trust.json
    managed_policy_arns     = optional(list(string), [])
    tags                    = optional(map(string), {})
  }))
  default = {}
}
