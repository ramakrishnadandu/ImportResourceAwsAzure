#!/usr/bin/env bash
# Reads existing IAM roles from AWS and writes:
#   iam-roles/policies/<role>-trust.json   (trust / assume-role policy)
#   iam-roles/roles.auto.tfvars.json       (existing_roles variable, overwritten)
# so the Terraform config matches the live roles exactly and the import plan is clean.
#
# Only needs the AWS CLI (no jq).
# Usage: ./discover-roles.sh role-name-1 role-name-2 ...
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <role-name> [<role-name> ...]" >&2
  exit 1
fi

cd "$(dirname "$0")/../iam-roles"
mkdir -p policies
out="roles.auto.tfvars.json"

# aws.exe on Windows emits CRLF; strip CR everywhere.
awsq() { aws "$@" | tr -d '\r'; }

json_escape() {
  local s="${1//\/\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

entries=()
for role in "$@"; do
  path=$(awsq iam get-role --role-name "$role" --query 'Role.Path' --output text)
  if [[ "$path" == /aws-service-role/* ]]; then
    echo "Skipping $role: service-linked roles are owned by AWS services, do not manage them" >&2
    continue
  fi
  echo "Reading $role ..." >&2

  description=$(awsq iam get-role --role-name "$role" --query 'Role.Description' --output json)
  max_session=$(awsq iam get-role --role-name "$role" --query 'Role.MaxSessionDuration' --output text)
  boundary=$(awsq iam get-role --role-name "$role" --query 'Role.PermissionsBoundary.PermissionsBoundaryArn' --output json)
  awsq iam get-role --role-name "$role" --query 'Role.AssumeRolePolicyDocument' --output json \
    > "policies/${role}-trust.json"

  policies=$(awsq iam list-attached-role-policies --role-name "$role" \
    --query 'AttachedPolicies[].PolicyArn' --output json | tr -d '\n' | tr -s ' ')

  tags=()
  while IFS=$'\t' read -r key value; do
    [ -z "$key" ] && continue
    tags+=("$(json_escape "$key"): $(json_escape "$value")")
  done < <(awsq iam list-role-tags --role-name "$role" --query 'Tags[].[Key,Value]' --output text)
  tags_json="{$(IFS=,; echo "${tags[*]:-}")}"

  inline=$(awsq iam list-role-policies --role-name "$role" --query 'length(PolicyNames)' --output text)
  if [ "$inline" != "0" ]; then
    echo "  WARNING: $role has $inline inline policy(ies); they are left unmanaged (add aws_iam_role_policy + import to manage them)" >&2
  fi

  entries+=("$(cat <<ENTRY
    $(json_escape "$role"): {
      "path": $(json_escape "$path"),
      "description": $description,
      "max_session_duration": $max_session,
      "permissions_boundary": $boundary,
      "assume_role_policy_file": "policies/${role}-trust.json",
      "managed_policy_arns": $policies,
      "tags": $tags_json
    }
ENTRY
)")
done

{
  echo '{'
  echo '  "existing_roles": {'
  (IFS=$'\n'; printf '%s' "${entries[0]:-}"; for e in "${entries[@]:1}"; do printf ',\n%s' "$e"; done)
  echo
  echo '  }'
  echo '}'
} > "$out"

echo "Wrote $(pwd)/$out" >&2
echo "Next: terraform fmt, then terraform plan -- expect only 'will be imported' and no changes." >&2
