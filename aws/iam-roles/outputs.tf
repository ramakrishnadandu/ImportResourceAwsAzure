output "role_arns" {
  description = "ARNs of the IAM roles now managed by Terraform."
  value       = { for name, role in aws_iam_role.this : name => role.arn }
}
