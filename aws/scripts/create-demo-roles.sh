#!/usr/bin/env bash
# Creates the demo IAM roles with the AWS CLI (i.e. OUTSIDE Terraform) so there is
# something "existing" to import. Skip this if you are importing your own roles.
#
# Usage: ./create-demo-roles.sh
set -euo pipefail

cd "$(dirname "$0")/../iam-roles"

create_role() {
  local name="$1" policy_arn="$2"

  if aws iam get-role --role-name "$name" >/dev/null 2>&1; then
    echo "Role $name already exists, skipping create"
  else
    aws iam create-role \
      --role-name "$name" \
      --description "Demo role created outside Terraform, then imported" \
      --assume-role-policy-document "file://policies/${name}-trust.json" \
      --tags Key=Purpose,Value=terraform-import-demo >/dev/null
    echo "Created role $name"
  fi

  aws iam attach-role-policy --role-name "$name" --policy-arn "$policy_arn"
  echo "Attached $policy_arn to $name"
}

create_role tf-import-demo-ec2-role    arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
create_role tf-import-demo-lambda-role arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
