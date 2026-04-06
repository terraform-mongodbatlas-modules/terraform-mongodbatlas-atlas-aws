locals {
  region                   = var.create_s3_bucket.region != null ? lower(replace(var.create_s3_bucket.region, "_", "-")) : null
  project_id_suffix_length = 8
  project_id_suffix        = substr(var.project_id, max(0, length(var.project_id) - local.project_id_suffix_length), local.project_id_suffix_length)
  default_name_prefix      = "atlas-logs-${local.project_id_suffix}-"
  bucket_name_prefix       = coalesce(var.create_s3_bucket.name_prefix, local.default_name_prefix)
  create_bucket            = var.create_s3_bucket.enabled
  bucket_name              = local.create_bucket ? aws_s3_bucket.atlas[0].id : var.bucket_name
  bucket_arn               = local.create_bucket ? aws_s3_bucket.atlas[0].arn : data.aws_s3_bucket.user_provided[0].arn

  byo_bucket_names = distinct(compact([for i in var.integrations : i.bucket_name]))
  all_target_buckets = distinct(compact(concat(
    [local.bucket_arn],
    [for b in data.aws_s3_bucket.integration_byo : b.arn],
  )))

  integrations_map  = { for idx, i in var.integrations : tostring(idx) => i }
  attach_kms_policy = var.kms_key != null && !var.kms_key_skip_iam
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
  region        = local.region
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

resource "aws_s3_bucket_lifecycle_configuration" "atlas" {
  count  = local.create_bucket && var.create_s3_bucket.expiration_days != null ? 1 : 0
  bucket = aws_s3_bucket.atlas[0].id

  rule {
    id     = "log-expiration"
    status = "Enabled"
    filter {}
    expiration {
      days = var.create_s3_bucket.expiration_days
    }
  }
}

data "aws_s3_bucket" "integration_byo" {
  for_each = toset(local.byo_bucket_names)
  bucket   = each.value
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = local.all_target_buckets
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = [for arn in local.all_target_buckets : "${arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_access" {
  name_prefix = "atlas-log-integration-"
  role        = var.iam_role_name
  policy      = data.aws_iam_policy_document.s3_access.json
}

data "aws_iam_policy_document" "kms_access" {
  count = local.attach_kms_policy ? 1 : 0
  statement {
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [var.kms_key]
  }
}

resource "aws_iam_role_policy" "kms_access" {
  count       = local.attach_kms_policy ? 1 : 0
  name_prefix = "atlas-log-integration-kms-"
  role        = var.iam_role_name
  policy      = data.aws_iam_policy_document.kms_access[0].json
}

resource "time_sleep" "iam_propagation" {
  depends_on      = [aws_iam_role_policy.s3_access, aws_iam_role_policy.kms_access, aws_s3_bucket.atlas]
  create_duration = "30s"
}

resource "mongodbatlas_log_integration" "this" {
  for_each    = local.integrations_map
  project_id  = var.project_id
  type        = "S3_LOG_EXPORT"
  iam_role_id = var.atlas_role_id
  bucket_name = coalesce(each.value.bucket_name, local.bucket_name)
  prefix_path = each.value.prefix_path
  log_types   = each.value.log_types

  kms_key = var.kms_key

  depends_on = [time_sleep.iam_propagation]
}
