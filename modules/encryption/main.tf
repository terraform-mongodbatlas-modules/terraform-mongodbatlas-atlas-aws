data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─────────────────────────────────────────────────────────────────────────────
# User-Provided KMS Key Lookup (when create_kms_key.enabled = false)
# ─────────────────────────────────────────────────────────────────────────────

data "aws_kms_key" "user_provided" {
  count  = local.create_kms_key ? 0 : 1
  key_id = var.kms_key_arn
}

locals {
  create_kms_key = var.create_kms_key.enabled
  aws_region     = lower(replace(coalesce(var.region, data.aws_region.current.id), "_", "-"))
  atlas_region   = upper(replace(local.aws_region, "-", "_"))
  kms_key_arn    = local.create_kms_key ? aws_kms_key.atlas[0].arn : var.kms_key_arn
  kms_key_id     = local.create_kms_key ? aws_kms_key.atlas[0].key_id : data.aws_kms_key.user_provided[0].key_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Module-Managed KMS Key (when create_kms_key.enabled = true)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_kms_key" "atlas" {
  count = local.create_kms_key ? 1 : 0

  description             = "Atlas Encryption at Rest"
  deletion_window_in_days = var.create_kms_key.deletion_window_in_days
  enable_key_rotation     = var.create_kms_key.enable_key_rotation
  policy                  = var.create_kms_key.policy_override
  tags                    = var.tags
}

resource "aws_kms_alias" "atlas" {
  count = local.create_kms_key ? 1 : 0

  name          = var.create_kms_key.alias
  target_key_id = aws_kms_key.atlas[0].key_id
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM Policy for KMS Access
# ─────────────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "kms_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [local.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "kms_access" {
  name_prefix = "atlas-kms-access-"
  role        = var.iam_role_name
  policy      = data.aws_iam_policy_document.kms_access.json
}

# ─────────────────────────────────────────────────────────────────────────────
# Atlas Encryption at Rest
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_encryption_at_rest" "this" {
  project_id = var.project_id

  aws_kms_config {
    enabled                    = true
    region                     = local.atlas_region
    role_id                    = var.role_id
    customer_master_key_id     = local.kms_key_id
    require_private_networking = var.require_private_networking
  }

  lifecycle {
    postcondition {
      condition     = self.aws_kms_config[0].valid
      error_message = "AWS KMS config is not valid"
    }
  }

  depends_on = [aws_iam_role_policy.kms_access]
}
