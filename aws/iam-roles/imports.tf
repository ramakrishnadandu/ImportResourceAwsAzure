# Config-driven imports (Terraform 1.5+, for_each since 1.7).
# The first `terraform plan` shows "will be imported"; `terraform apply` writes the
# existing roles into the S3 state without creating or changing anything in AWS.
# After a successful apply these blocks become no-ops, so they can stay in the code.

import {
  for_each = var.existing_roles
  to       = aws_iam_role.this[each.key]
  id       = each.key # import ID for aws_iam_role = role name
}

import {
  for_each = local.role_policy_attachments
  to       = aws_iam_role_policy_attachment.this[each.key]
  id       = "${each.value.role}/${each.value.policy_arn}" # "<role-name>/<policy-arn>"
}
