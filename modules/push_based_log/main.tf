locals {
  bucket_arn    = var.create_s3_bucket ? aws_s3_bucket.log_bucket[0].arn : "arn:aws:s3:::${var.bucket_name}"
  role_name     = var.create_iam_role ? aws_iam_role.this[0].name : var.existing_iam_role_name
  atlas_role_id = var.create_iam_role ? mongodbatlas_cloud_provider_access_authorization.this[0].role_id : var.atlas_role_id
}

#------------------------------------------------------------------------------
# S3 Bucket (optional)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  count = var.create_s3_bucket ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = true # required for destroying as Atlas may create a test folder in the bucket when push-based log export is set up
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {} # Apply to all objects

    expiration {
      days = var.log_retention_days
    }
  }
}

#------------------------------------------------------------------------------
# Cloud Provider Access (created when create_iam_role = true)
#------------------------------------------------------------------------------

resource "mongodbatlas_cloud_provider_access_setup" "this" {
  count = var.create_iam_role ? 1 : 0

  project_id    = var.project_id
  provider_name = "AWS"
}

resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = mongodbatlas_cloud_provider_access_setup.this[0].aws_config[0].atlas_aws_account_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = mongodbatlas_cloud_provider_access_setup.this[0].aws_config[0].atlas_assumed_role_external_id
          }
        }
      }
    ]
  })

  tags = var.aws_tags
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  count = var.create_iam_role ? 1 : 0

  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.this[0].role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.this[0].arn
  }
}

#------------------------------------------------------------------------------
# IAM Policy for S3 Access
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "s3_bucket_policy" {
  name = var.bucket_policy_name
  role = local.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          local.bucket_arn,
          "${local.bucket_arn}/*"
        ]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Push Based Log Export
#------------------------------------------------------------------------------

resource "mongodbatlas_push_based_log_export" "this" {
  project_id  = var.project_id
  bucket_name = var.bucket_name
  iam_role_id = local.atlas_role_id
  prefix_path = var.prefix_path

  timeouts = var.timeouts

  depends_on = [
    aws_iam_role_policy.s3_bucket_policy,
    mongodbatlas_cloud_provider_access_authorization.this
  ]
}
