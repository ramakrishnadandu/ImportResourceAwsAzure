locals {
  # One entry per role/policy pair, keyed "role-name|policy-arn".
  role_policy_attachments = merge([
    for role_name, role in var.existing_roles : {
      for arn in role.managed_policy_arns :
      "${role_name}|${arn}" => {
        role       = role_name
        policy_arn = arn
      }
    }
  ]...)
}

resource "aws_iam_role" "this" {
  for_each = var.existing_roles

  name                 = each.key
  path                 = each.value.path
  description          = each.value.description
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary
  assume_role_policy   = file("${path.module}/${each.value.assume_role_policy_file}")
  tags                 = each.value.tags

  # These roles pre-date Terraform and may be used by running workloads;
  # never let a bad change delete them.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.role_policy_attachments

  role       = aws_iam_role.this[each.value.role].name
  policy_arn = each.value.policy_arn
}
