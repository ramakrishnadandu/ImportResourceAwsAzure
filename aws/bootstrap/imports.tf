# If the state bucket was created by hand (or by an earlier run whose state was lost),
# run with -var="import_existing_bucket=true" and Terraform adopts it instead of failing
# with BucketAlreadyOwnedByYou. The GitHub workflow sets this automatically.
#
# Only the bucket and its settings that cannot simply be overwritten need importing;
# ownership controls, lifecycle and bucket policy are PUT operations and are
# overwritten by a normal create.

locals {
  bucket_to_import = var.import_existing_bucket ? toset([var.state_bucket_name]) : toset([])
}

import {
  for_each = local.bucket_to_import
  to       = aws_s3_bucket.tfstate
  id       = each.value
}

import {
  for_each = local.bucket_to_import
  to       = aws_s3_bucket_versioning.tfstate
  id       = each.value
}

import {
  for_each = local.bucket_to_import
  to       = aws_s3_bucket_server_side_encryption_configuration.tfstate
  id       = each.value
}

import {
  for_each = local.bucket_to_import
  to       = aws_s3_bucket_public_access_block.tfstate
  id       = each.value
}
