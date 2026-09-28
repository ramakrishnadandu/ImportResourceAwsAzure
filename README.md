# ImportResourceAwsAzure

Examples of bringing **existing cloud resources under Terraform** with `import` blocks,
state stored remotely, and everything run from GitHub Actions.

## AWS: import existing IAM roles

```
aws/
├── bootstrap/                 # S3 bucket that holds Terraform state (versioned, encrypted, TLS-only)
│   ├── main.tf
│   ├── imports.tf             # adopts the bucket if it already exists
│   └── versions.tf            # backend "s3" – the bootstrap keeps its own state in the bucket
├── iam-roles/                 # the import example
│   ├── main.tf                # aws_iam_role + aws_iam_role_policy_attachment (for_each)
│   ├── imports.tf             # import blocks driven by the same map
│   ├── roles.auto.tfvars.json # WHICH roles to import (edit this / generate it)
│   └── policies/*-trust.json  # trust policy of each role
└── scripts/
    ├── create-demo-roles.sh   # makes demo roles with the AWS CLI (simulates "existing")
    └── discover-roles.sh      # reads real roles from AWS -> writes tfvars + trust policies
.github/workflows/
├── aws-tf-backend-bootstrap.yml
└── aws-iam-roles-import.yml
```

### How the import works

`imports.tf` uses config-driven import (Terraform ≥ 1.7 for `for_each`):

```hcl
import {
  for_each = var.existing_roles
  to       = aws_iam_role.this[each.key]
  id       = each.key
}
```

1. `terraform plan` → `aws_iam_role.this["x"] will be imported` – nothing is created.
2. `terraform apply` → the role is written into the state file in S3. AWS is untouched.
3. From then on the role is managed like any other resource. The import blocks
   become no-ops and can stay in the code.

Roles have `prevent_destroy = true`, and the pipeline **fails if the plan would delete
or replace anything**, so a mismatch between code and the live role can never remove it.
If the plan shows *updates* next to the imports, your tfvars don't match the live role –
regenerate them with `discover-roles.sh`.

State locking uses S3 native lock files (`use_lockfile = true`, Terraform ≥ 1.10), so no
DynamoDB table is needed.

---

## One-time setup

### 1. Let GitHub Actions log in to AWS (OIDC, no access keys)

Run once with admin credentials (replace `ACCOUNT_ID`; `ramakrishnadandu/ImportResourceAwsAzure` is this repo):

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

cat > gha-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike":   { "token.actions.githubusercontent.com:sub": "repo:ramakrishnadandu/ImportResourceAwsAzure:*" }
    }
  }]
}
EOF

aws iam create-role --role-name github-actions-terraform \
  --assume-role-policy-document file://gha-trust.json
```

Permissions the role needs:

| Stack | Permissions |
|---|---|
| bootstrap | `s3:*` on `arn:aws:s3:::<state-bucket>` and `arn:aws:s3:::<state-bucket>/*` |
| iam-roles | `iam:GetRole`, `iam:ListRoleTags`, `iam:ListAttachedRolePolicies`, `iam:ListRolePolicies`, `iam:ListInstanceProfilesForRole`, `iam:UpdateRole`, `iam:UpdateAssumeRolePolicy`, `iam:TagRole`, `iam:UntagRole`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`, `iam:PutRolePermissionsBoundary` on the roles you import |

For a learning account, attaching `AdministratorAccess` is the quick option; scope it down for real use.

### 2. GitHub repository settings

*Settings → Secrets and variables → Actions*

| Type | Name | Example |
|---|---|---|
| Secret | `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/github-actions-terraform` |
| Variable | `AWS_REGION` | `us-east-1` |
| Variable | `TF_STATE_BUCKET` | `tfstate-123456789012-us-east-1` (must be globally unique) |

*Settings → Environments* → create **`aws-prod`** and add yourself as a required reviewer.
Every apply waits for your approval.

### 3. Create the state bucket

*Actions → "AWS - Terraform backend (S3) bootstrap" → Run workflow → `apply`*

The workflow checks the bucket first:

| Bucket | Bootstrap state | What happens |
|---|---|---|
| missing | – | creates the bucket with local state, then `init -migrate-state` moves the state into the bucket |
| exists | missing | imports the existing bucket (`import_existing_bucket=true`) |
| exists | exists | normal plan/apply – fixes drift, applies setting changes |

Re-run it any time to keep the bucket settings (versioning, encryption, public access block,
TLS-only policy, old-version expiry) as defined in code.

### 4. Import roles

**Try it with the demo roles** (they are already listed in `roles.auto.tfvars.json`):

```bash
./aws/scripts/create-demo-roles.sh       # creates the roles outside Terraform
```

**Or import your own roles:**

```bash
./aws/scripts/discover-roles.sh my-app-role my-ci-role   # overwrites roles.auto.tfvars.json
```

Then commit on a branch and open a PR:

- **PR** → plan runs; the job summary shows `Imports: 2  Creates: 0  Updates: 0`.
- **Merge to main** → after approval in `aws-prod`, apply imports the roles into
  `s3://<bucket>/iam-roles/terraform.tfstate`.

Adding a role later = add it to the tfvars (or re-run discovery with all names) and open another PR.

---

## Running locally

```bash
cd aws/iam-roles
cp example.backend.hcl dev.backend.hcl     # put your bucket/region in it (git-ignored)
terraform init -backend-config=dev.backend.hcl
terraform plan
```

Alternative to writing the resource code by hand: let Terraform generate it from the live
resource. Add only an `import` block, then run

```bash
terraform plan -generate-config-out=generated.tf
```

and copy what you need from `generated.tf` into your own files.

## Removing a role from Terraform without deleting it

Take it out of state first, then out of the tfvars (otherwise the next apply would try to
delete it – `prevent_destroy` stops protecting a resource once its config is gone):

```bash
terraform state rm 'aws_iam_role.this["my-app-role"]'
terraform state rm 'aws_iam_role_policy_attachment.this["my-app-role|arn:aws:iam::aws:policy/..."]'
```

Then delete the role's entry from `roles.auto.tfvars.json` and open a PR – the plan shows no changes.

## Azure

Coming next under `azure/`.
