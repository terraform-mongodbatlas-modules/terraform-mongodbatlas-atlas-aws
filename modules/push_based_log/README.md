# MongoDB Atlas Push-Based Log Export Module

Configures MongoDB Atlas push-based log export to an S3 bucket.

## Usage

```hcl
module "push_based_log" {
  source = "./modules/push_based_log"

  project_id = "your-atlas-project-id"

  # Create new S3 bucket and IAM role
  bucket_name       = "my-atlas-logs-bucket"
  create_s3_bucket  = true
  create_iam_role   = true

  # Optional: customize settings
  aws_iam_role_name  = "atlas-push-based-log-role"
  prefix_path        = "mongodb/logs"
  log_retention_days = 90
}
```

## Use Cases

The module supports four configurations via boolean flags:

| `create_s3_bucket` | `create_iam_role` | Description |
|--------------------|-------------------|-------------|
| `true` | `true` | Create new S3 bucket and dedicated IAM role |
| `true` | `false` | Create new S3 bucket, use shared IAM role |
| `false` | `true` | Use existing S3 bucket, create dedicated IAM role |
| `false` | `false` | Use existing S3 bucket and shared IAM role |

## Features

- **S3 Lifecycle Policy**: When creating a new bucket, logs are automatically deleted after `log_retention_days` (default: 90 days)
- **Flexible IAM**: Create a dedicated IAM role or use a shared one
- **Bucket Name Only**: Uses S3 bucket name (globally unique) instead of ARN for simpler configuration
