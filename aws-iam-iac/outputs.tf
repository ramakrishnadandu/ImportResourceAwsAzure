output "role_name" {
  description = "Name of the EC2 IAM role."
  value       = aws_iam_role.ec2_s3.name
}

output "role_arn" {
  description = "ARN of the EC2 IAM role."
  value       = aws_iam_role.ec2_s3.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile to attach to an EC2 instance."
  value       = aws_iam_instance_profile.ec2_s3.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2_s3.arn
}
