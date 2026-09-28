## Create an EC2 role with scoped S3 access (AWS CLI)

The `aws-iam` folder contains a Bash script that creates an IAM role trusted by
EC2, attaches an inline permissions policy, and creates an instance profile.
The policy allows EC2 inventory reads and S3 object read/write/delete access
only in the bucket you specify. `s3:ListBucket` is scoped to that bucket.

Prerequisites: AWS CLI configured with credentials that can create IAM roles,
inline role policies, and instance profiles; Python 3; and an existing S3
bucket. Run from Bash, WSL, or Git Bash:

```bash
cd aws-iam
BUCKET_NAME=my-existing-bucket ./create-ec2-s3-role.sh
```

Optional environment variables: `ROLE_NAME`, `POLICY_NAME`, `PROFILE_NAME`,
and `AWS_REGION`. The default role and profile names are `Ec2S3AccessRole`.
The script creates AWS resources and fails if those names already exist; choose
new names or remove the existing resources before rerunning it.

After creation, attach the instance profile to an EC2 instance (or select it
when launching one). The instance can then use its instance role credentials to
access the configured bucket. The policy does not grant permission to start,
stop, or modify EC2 instances. If the bucket uses SSE-KMS, grant the required
KMS permissions separately.

Review the policy template before running it and replace the bucket scope with
the narrowest resources your workload needs. Avoid using root credentials.
