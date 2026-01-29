locals {
  project_id_suffix_length = 8 # last 8 chars of project ID for unique, readable naming
  create_bucket            = var.create_s3_bucket.enabled
  project_id_suffix        = substr(var.project_id, max(0, length(var.project_id) - local.project_id_suffix_length), local.project_id_suffix_length)
  default_name_prefix      = "atlas-backup-${local.project_id_suffix}-"
  bucket_name_prefix       = coalesce(var.create_s3_bucket.name_prefix, local.default_name_prefix)
  bucket_name              = local.create_bucket ? aws_s3_bucket.atlas[0].id : var.bucket_name
  bucket_arn               = local.create_bucket ? aws_s3_bucket.atlas[0].arn : data.aws_s3_bucket.user_provided[0].arn
}

data "aws_s3_bucket" "user_provided" {
  count  = local.create_bucket ? 0 : 1
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "atlas" {
  count         = local.create_bucket ? 1 : 0
  bucket        = var.create_s3_bucket.name
  bucket_prefix = var.create_s3_bucket.name != null ? null : local.bucket_name_prefix
  force_destroy = var.create_s3_bucket.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "atlas" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.atlas[0].id

  versioning_configuration {
    status = var.create_s3_bucket.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "atlas" {
  count  = local.create_bucket && var.create_s3_bucket.server_side_encryption != null ? 1 : 0
  bucket = aws_s3_bucket.atlas[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.create_s3_bucket.server_side_encryption
    }
  }
}

resource "aws_s3_bucket_public_access_block" "atlas" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.atlas[0].id

  block_public_acls       = var.create_s3_bucket.block_public_acls
  block_public_policy     = var.create_s3_bucket.block_public_policy
  ignore_public_acls      = var.create_s3_bucket.ignore_public_acls
  restrict_public_buckets = var.create_s3_bucket.restrict_public_buckets
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = [local.bucket_arn]
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name_prefix = "atlas-backup-export-"
  role        = var.iam_role_name
  policy      = data.aws_iam_policy_document.s3_access.json
}

resource "mongodbatlas_cloud_backup_snapshot_export_bucket" "this" {
  project_id     = var.project_id
  iam_role_id    = var.atlas_role_id
  bucket_name    = local.bucket_name
  cloud_provider = "AWS"

  depends_on = [aws_iam_role_policy.s3_access]
}
