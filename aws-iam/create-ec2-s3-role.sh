#!/usr/bin/env bash
set -euo pipefail

# Create an EC2 instance role with read-only EC2 inventory access and
# object read/write/delete access limited to one S3 bucket.
ROLE_NAME="${ROLE_NAME:-Ec2S3AccessRole}"
POLICY_NAME="${POLICY_NAME:-Ec2S3AccessPolicy}"
BUCKET_NAME="${BUCKET_NAME:-}"
PROFILE_NAME="${PROFILE_NAME:-$ROLE_NAME}"
AWS_REGION="${AWS_REGION:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Git Bash reports files as /d/... paths, but the Windows AWS CLI needs native
# Windows paths when it opens file:// parameters. cygpath preserves spaces.
aws_file_uri() {
  local path="$1"
  if command -v cygpath >/dev/null 2>&1; then
    path="$(cygpath -w "$path")"
  fi
  printf 'file://%s' "$path"
}

if [[ -z "$BUCKET_NAME" ]]; then
  echo "Set BUCKET_NAME to the target S3 bucket name." >&2
  exit 2
fi

AWS_ARGS=()
if [[ -n "$AWS_REGION" ]]; then
  AWS_ARGS+=(--region "$AWS_REGION")
fi

TMP_POLICY="$(mktemp)"
trap 'rm -f "$TMP_POLICY"' EXIT

python - "$SCRIPT_DIR/ec2-s3-access-policy.template.json" "$TMP_POLICY" "$BUCKET_NAME" <<'PY'
import json
import sys

template_path, output_path, bucket_name = sys.argv[1:]
with open(template_path, encoding="utf-8") as src:
    policy = json.load(src)
for statement in policy["Statement"]:
    resources = statement["Resource"]
    if isinstance(resources, str):
        statement["Resource"] = resources.replace("REPLACE_WITH_BUCKET_NAME", bucket_name)
    else:
        statement["Resource"] = [r.replace("REPLACE_WITH_BUCKET_NAME", bucket_name) for r in resources]
with open(output_path, "w", encoding="utf-8") as dst:
    json.dump(policy, dst, indent=2)
PY

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$(aws_file_uri "$SCRIPT_DIR/ec2-s3-role-trust.json")" \
  "${AWS_ARGS[@]}"

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document "$(aws_file_uri "$TMP_POLICY")" \
  "${AWS_ARGS[@]}"

aws iam create-instance-profile \
  --instance-profile-name "$PROFILE_NAME" \
  "${AWS_ARGS[@]}"

aws iam add-role-to-instance-profile \
  --instance-profile-name "$PROFILE_NAME" \
  --role-name "$ROLE_NAME" \
  "${AWS_ARGS[@]}"

printf 'Created role %s and instance profile %s for bucket %s.\n' "$ROLE_NAME" "$PROFILE_NAME" "$BUCKET_NAME"
printf 'Attach profile %s to an EC2 instance (or launch one with this profile).\n' "$PROFILE_NAME"
