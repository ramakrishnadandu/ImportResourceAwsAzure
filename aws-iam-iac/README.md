# EC2 and S3 IAM role (Terraform)

This configuration creates an IAM role trusted by EC2, an inline policy, and
an instance profile. The policy allows EC2 inventory reads and S3
list/read/write/delete access scoped to one existing bucket. It does not grant
permissions to start, stop, or modify EC2 instances.

## Prerequisites

- Terraform 1.5 or later
- AWS CLI credentials available through the standard AWS provider chain
- Permission to manage IAM roles, inline role policies, and instance profiles
- The target S3 bucket already exists

## Apply

From this directory, copy `terraform.tfvars.example` to `terraform.tfvars`.
It is configured for `Ec2S3AccessRole` and the bucket
`arn:aws:s3:::tfbackendrkd-us-east-1`. Adjust the values if needed, then run:

```bash
terraform init
terraform plan
terraform apply
```

The `terraform.tfvars` file is ignored by Git. Terraform creates AWS resources
when you apply the configuration. Attach the resulting instance profile to an
EC2 instance, or select it when launching an instance. The EC2 instance can
then use its role credentials to access the bucket.

If the bucket uses SSE-KMS, grant the required KMS permissions separately.
IAM is global; `aws_region` configures the provider's region.

## Import and apply through GitHub Actions

The repository workflow at `.github/workflows/import-ec2-s3-role.yml` is
manually triggered from GitHub Actions. It initializes the S3 backend, imports
the existing `Ec2S3AccessRole`, inline policy, and instance profile if they are
not already in state, then runs `terraform plan` and `terraform apply`.
The backend type is declared in `backend.tf`; the workflow supplies the bucket,
state key, region, encryption, and S3 lockfile settings during `terraform init`.

Before running it:

1. In GitHub repository settings, create an environment named
   `aws-production`. Add required reviewers if you want an approval gate before
   the job can apply.
2. Open that environment and add secrets named `AWS_ACCESS_KEY_ID` and
   `AWS_SECRET_ACCESS_KEY`. If using temporary AWS credentials, also add
   `AWS_SESSION_TOKEN`. The AWS identity needs permission to manage the IAM
   resources and access the S3 backend state object and `.tflock` object. Store
   credentials as secrets, not variables.
3. Run **Actions → Import and apply EC2 S3 IAM role → Run workflow**.

The workflow is configured for manual dispatch only. Run Terraform apply from
this workflow so the state and AWS changes are handled by GitHub Actions. If you
run other Terraform commands locally, initialize with the same `-backend-config`
values used by the workflow so those commands target the same S3 state.
