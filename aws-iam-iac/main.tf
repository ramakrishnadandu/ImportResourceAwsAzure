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

resource "aws_iam_instance_profile" "ec2_s3" {
  name = var.instance_profile_name
  role = aws_iam_role.ec2_s3.name
}
