# EC2 is the only service allowed to assume this role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_s3" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Custom inline policy: EC2 inventory reads and object access to the configured bucket.
data "aws_iam_policy_document" "ec2_s3_access" {
  statement {
    sid       = "DescribeEc2Resources"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeVolumes", "ec2:DescribeTags"]
    resources = ["*"]
  }

  statement {
    sid       = "ListConfiguredBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]
  }

  statement {
    sid    = "ReadWriteObjectsInConfiguredBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "ec2_s3_access" {
  name   = var.policy_name
  role   = aws_iam_role.ec2_s3.id
  policy = data.aws_iam_policy_document.ec2_s3_access.json
}

# Existing AWS-managed policy attached to this role in IAM.
resource "aws_iam_role_policy_attachment" "agent_registry_full_access" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AgentRegistryFullAccess"
}

# Makes the role available for attachment to EC2 instances.
resource "aws_iam_instance_profile" "ec2_s3" {
  name = var.instance_profile_name
  role = aws_iam_role.ec2_s3.name
}
