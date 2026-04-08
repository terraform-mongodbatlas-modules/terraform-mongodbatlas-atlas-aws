# IAM Permissions Reference

This page documents the least-privilege IAM permissions the `atlas-aws` module requires. The module operates in two IAM scopes:

- **CPA role** -- the IAM role Atlas assumes via [Cloud Provider Access](https://www.mongodb.com/docs/atlas/security/set-up-unified-aws-access/). The module attaches inline policies to this role automatically. Platform teams replicate these policies manually when using `skip_iam_policy_attachments = true` (planned, not yet implemented)
- **Terraform caller** -- the IAM identity (user, role, or CI runner) that runs `terraform apply`. This identity creates and manages the AWS resources the module provisions

## CPA Role Permissions

The module attaches these inline policies to the CPA IAM role via `aws_iam_role_policy` resources. Atlas uses these permissions at runtime to interact with AWS services.

Note: the module skips CPA creation entirely when only PrivateLink is configured (no encryption, backup export, or log integration). In that case, none of the policies below apply.

### Encryption (KMS)

- **`kms:Encrypt`** -- encrypt data at rest
- **`kms:Decrypt`** -- decrypt data at rest
- **`kms:GenerateDataKey*`** -- generate data encryption keys for envelope encryption
- **`kms:DescribeKey`** -- validate the KMS key exists and retrieve metadata
- **Resource:** the KMS key ARN (module-managed or BYO)

Source: `modules/encryption/main.tf` -- `data.aws_iam_policy_document.kms_access`

### Backup Export (S3)

- **`s3:GetBucketLocation`** -- determine the bucket's region for API routing
- **`s3:PutObject`** -- write backup snapshot exports
- **Resources:** bucket ARN (for `GetBucketLocation`), `{bucket_arn}/*` (for `PutObject`)

Source: `modules/backup_export/main.tf` -- `data.aws_iam_policy_document.s3_access`

### Log Integration (S3)

- **`s3:GetBucketLocation`** -- determine each target bucket's region
- **`s3:PutObject`** -- write log files to S3
- **Resources:** all target bucket ARNs (module-managed + BYO + per-integration overrides)

Source: `modules/log_integration/main.tf` -- `data.aws_iam_policy_document.s3_access`

### Log Integration (KMS, optional)

The module attaches this policy only when `kms_key` is set and `kms_key_skip_iam_policy = false`:

- **`kms:GenerateDataKey`** -- generate data keys for Atlas-side log encryption before delivery to S3
- **`kms:Decrypt`** -- decrypt data keys
- **`kms:DescribeKey`** -- validate the KMS key
- **Resource:** the KMS key ARN

Source: `modules/log_integration/main.tf` -- `data.aws_iam_policy_document.kms_access`

Note: `kms_key_skip_iam_policy = true` skips this KMS policy. `skip_iam_policy_attachments = true` (planned) skips all policies including this one.

### PrivateLink

PrivateLink uses VPC endpoints, not IAM role policies. The module attaches no CPA role permissions for PrivateLink.

### Encryption Private Endpoint

Atlas manages the PrivateLink connection to KMS internally. The module creates no AWS resources and attaches no CPA role permissions for encryption private endpoints.

## Terraform Caller Permissions

The Terraform caller needs permissions to create and manage the AWS resources the module provisions. Each section below lists the minimum actions required per feature.

### Cloud Provider Access

The module creates an `aws_iam_role` with a trust policy allowing Atlas to assume it.

- **IAM role management:**
  - `iam:CreateRole`, `iam:GetRole`, `iam:DeleteRole`
  - `iam:UpdateAssumeRolePolicy`
  - `iam:ListRolePolicies`, `iam:ListAttachedRolePolicies`
  - `iam:TagRole`, `iam:UntagRole` (when `aws_tags` is set)
- **Resource scope:** `arn:aws:iam::*:role/mongodb-atlas-*` (default name prefix) or the custom name set via `iam_role_name`

When `cloud_provider_access.create = false`, the caller needs no IAM role permissions for CPA.

### Encryption

**Module-managed KMS key** (`create_kms_key.enabled = true`):

- **KMS key:**
  - `kms:CreateKey`, `kms:DescribeKey`, `kms:GetKeyPolicy`, `kms:GetKeyRotationStatus`
  - `kms:EnableKeyRotation`, `kms:ScheduleKeyDeletion`
  - `kms:TagResource`, `kms:UntagResource`, `kms:ListResourceTags`
- **KMS alias:**
  - `kms:CreateAlias`, `kms:DeleteAlias`
- **IAM policy attachment:**
  - `iam:PutRolePolicy`, `iam:GetRolePolicy`, `iam:DeleteRolePolicy`

**BYO KMS key** (`kms_key_arn` set):

- `kms:DescribeKey` on the key ARN (data source lookup)
- `iam:PutRolePolicy`, `iam:GetRolePolicy`, `iam:DeleteRolePolicy` (to attach the inline policy to the CPA role)

### Backup Export

**Module-managed S3 bucket** (`create_s3_bucket.enabled = true`):

- **S3 bucket:**
  - `s3:CreateBucket`, `s3:DeleteBucket`, `s3:ListBucket`
  - `s3:GetBucketLocation`, `s3:GetBucketTagging`, `s3:PutBucketTagging`
  - `s3:GetBucketVersioning`, `s3:PutBucketVersioning`
  - `s3:GetEncryptionConfiguration`, `s3:PutEncryptionConfiguration`
  - `s3:GetBucketPublicAccessBlock`, `s3:PutBucketPublicAccessBlock`
- **IAM policy attachment:**
  - `iam:PutRolePolicy`, `iam:GetRolePolicy`, `iam:DeleteRolePolicy`

**BYO S3 bucket** (`bucket_name` set):

- `s3:ListBucket`, `s3:GetBucketLocation` on the bucket (data source lookup)
- `iam:PutRolePolicy`, `iam:GetRolePolicy`, `iam:DeleteRolePolicy`

### Backup Export (S3 lifecycle)

When `expiration_days` is set on module-managed buckets (default 365):

- `s3:GetLifecycleConfiguration`, `s3:PutLifecycleConfiguration`

### Log Integration

Same S3 bucket management permissions as Backup Export above (create, delete, versioning, encryption, public access block, lifecycle, IAM policy attachment). Additionally:

- **Per-integration BYO buckets:** `s3:ListBucket`, `s3:GetBucketLocation` on each BYO bucket (data source lookup)
- **KMS policy attachment** (when `kms_key` is set): `iam:PutRolePolicy`, `iam:GetRolePolicy`, `iam:DeleteRolePolicy` for the KMS inline policy

### PrivateLink

**Module-managed VPC endpoint** (`privatelink_endpoints`):

- **VPC endpoint:**
  - `ec2:CreateVpcEndpoint`, `ec2:DeleteVpcEndpoints`
  - `ec2:DescribeVpcEndpoints`, `ec2:ModifyVpcEndpoint`
- **Security group** (when `security_group.create = true`):
  - `ec2:CreateSecurityGroup`, `ec2:DeleteSecurityGroup`, `ec2:DescribeSecurityGroups`
  - `ec2:AuthorizeSecurityGroupIngress`, `ec2:RevokeSecurityGroupIngress`
- **Data sources:**
  - `ec2:DescribeSubnets` (subnet lookup for VPC ID)
  - `ec2:DescribeVpcs` (VPC CIDR for default security group rules)
- **Tagging:** `ec2:CreateTags`, `ec2:DeleteTags`

**BYOE** (`privatelink_byoe`):

- `ec2:DescribeVpcEndpoints` (data source lookup on the BYO endpoint)

## BYO Role with Read-Only AWS Access (planned)

> **Follow-up:** `skip_iam_policy_attachments` is not yet implemented. This section describes the planned behavior pending a design decision on how platform teams opt out of module-managed IAM policy attachments. Do not rely on this section until the feature ships.

When `cloud_provider_access.create = false` and `skip_iam_policy_attachments = true`, the module would create zero `aws_iam_role` and zero `aws_iam_role_policy` resources. The Terraform caller would only need read-only AWS access for data source lookups.

### Minimal Terraform caller policy

Each statement below applies only when the corresponding feature is enabled. Drop statements for features you do not use.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "KmsReadOnly",
      "Effect": "Allow",
      "Action": "kms:DescribeKey",
      "Resource": "<kms-key-arn>"
    },
    {
      "Sid": "S3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "<backup-bucket-arn>",
        "<log-bucket-arn>"
      ]
    },
    {
      "Sid": "VpcEndpointReadOnly",
      "Effect": "Allow",
      "Action": "ec2:DescribeVpcEndpoints",
      "Resource": "*"
    }
  ]
}
```

- **`KmsReadOnly`** -- needed when `encryption.enabled = true` with a BYO KMS key
- **`S3ReadOnly`** -- needed when `backup_export` or `log_integration` uses a BYO bucket. Include per-integration BYO bucket ARNs for log integration
- **`VpcEndpointReadOnly`** -- needed when using `privatelink_byoe`. `ec2:Describe*` actions do not support resource-level restrictions, so the resource must be `*`

### Platform team responsibilities

When `skip_iam_policy_attachments` ships, the platform team must pre-attach these policies to the CPA IAM role before the app team runs `terraform apply`:

- **Encryption:** `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey*`, `kms:DescribeKey` on the KMS key
- **Backup export:** `s3:GetBucketLocation`, `s3:PutObject` on the backup bucket
- **Log integration:** `s3:GetBucketLocation`, `s3:PutObject` on all target log buckets
- **Log integration KMS** (when `kms_key` is set): `kms:GenerateDataKey`, `kms:Decrypt`, `kms:DescribeKey` on the KMS key

These match the CPA role permissions in the first section of this document. The module normally attaches them automatically; `skip_iam_policy_attachments` would shift that responsibility to the platform team.

## Reference IAM Policy Examples

### Full module-managed (all features)

Terraform caller policy when using module-managed KMS key, S3 buckets, and VPC endpoints with default naming:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IamRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "arn:aws:iam::<account-id>:role/mongodb-atlas-*"
    },
    {
      "Sid": "KmsKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:EnableKeyRotation",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KmsAliasManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateAlias",
        "kms:DeleteAlias"
      ],
      "Resource": [
        "arn:aws:kms:*:<account-id>:alias/atlas-encryption",
        "arn:aws:kms:*:<account-id>:key/*"
      ]
    },
    {
      "Sid": "S3BucketManagement",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetEncryptionConfiguration",
        "s3:PutEncryptionConfiguration",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetLifecycleConfiguration",
        "s3:PutLifecycleConfiguration"
      ],
      "Resource": "arn:aws:s3:::atlas-*"
    },
    {
      "Sid": "VpcEndpointManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:DescribeVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    }
  ]
}
```

### CPA + encryption only

Terraform caller policy for encryption with a module-managed KMS key (no S3, no PrivateLink):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IamRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "arn:aws:iam::<account-id>:role/mongodb-atlas-*"
    },
    {
      "Sid": "KmsKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:EnableKeyRotation",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KmsAliasManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateAlias",
        "kms:DeleteAlias"
      ],
      "Resource": [
        "arn:aws:kms:*:<account-id>:alias/atlas-encryption",
        "arn:aws:kms:*:<account-id>:key/*"
      ]
    }
  ]
}
```

## Notes

- Replace `<account-id>` with your AWS account ID in the reference policies above
- The KMS alias ARN (`alias/atlas-encryption`) matches the module default. If you override `create_kms_key.alias`, update the alias ARN accordingly
- The Terraform caller permissions depend on the AWS provider version. Consult the [AWS IAM Actions Reference](https://docs.aws.amazon.com/service-authorization/latest/reference/reference.html) for the authoritative list of actions per resource type
- `ec2:Describe*` actions do not support resource-level restrictions. The resource must be `*`
- `kms:CreateKey` does not support resource-level restrictions (the key does not exist yet). Scope KMS management actions to `*` and use [KMS key policies](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html) for additional access control
- The module uses inline IAM policies (`aws_iam_role_policy`), not managed policies (`aws_iam_policy`). The caller needs `iam:PutRolePolicy` / `iam:GetRolePolicy` / `iam:DeleteRolePolicy`, not `iam:AttachRolePolicy` / `iam:DetachRolePolicy`
