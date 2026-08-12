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
  aws_region     = lower(replace(coalesce(var.region, data.aws_region.current.region), "_", "-"))
  atlas_region   = upper(replace(local.aws_region, "-", "_"))
  kms_replica_regions = toset([
    for region in try(var.create_kms_key.replica_regions, []) :
    lower(replace(region, "_", "-"))
    if lower(replace(region, "_", "-")) != local.aws_region
  ])
  multi_region_kms    = local.create_kms_key && try(var.create_kms_key.multi_region, true)
  create_kms_replicas = local.multi_region_kms && length(local.kms_replica_regions) > 0
  kms_key_arn         = local.create_kms_key ? aws_kms_key.atlas[0].arn : var.kms_key_arn
  kms_key_id          = local.create_kms_key ? aws_kms_key.atlas[0].key_id : data.aws_kms_key.user_provided[0].key_id
  kms_key_arns = local.create_kms_key ? concat(
    [aws_kms_key.atlas[0].arn],
    [for replica in aws_kms_replica_key.atlas : replica.arn]
  ) : [var.kms_key_arn]
}

# ─────────────────────────────────────────────────────────────────────────────
# Module-Managed KMS Key (when create_kms_key.enabled = true)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_kms_key" "atlas" {
  count = local.create_kms_key ? 1 : 0

  description             = "Atlas Encryption at Rest"
  multi_region            = local.multi_region_kms
  deletion_window_in_days = var.create_kms_key.deletion_window_in_days
  enable_key_rotation     = var.create_kms_key.enable_key_rotation
  policy                  = var.create_kms_key.policy_override
  tags                    = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
    }
  }
}

resource "aws_kms_replica_key" "atlas" {
  for_each = local.create_kms_replicas ? local.kms_replica_regions : toset([])

  region                  = each.key
  primary_key_arn         = aws_kms_key.atlas[0].arn
  description             = "Atlas Encryption at Rest replica (${each.key})"
  deletion_window_in_days = var.create_kms_key.deletion_window_in_days
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
  count = var.skip_iam_policy_attachments ? 0 : 1
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = local.kms_key_arns
  }
}

resource "aws_iam_role_policy" "kms_access" {
  count       = var.skip_iam_policy_attachments ? 0 : 1
  name_prefix = "atlas-kms-access-"
  role        = var.iam_role_name
  policy      = data.aws_iam_policy_document.kms_access[0].json
}

moved {
  from = aws_iam_role_policy.kms_access
  to   = aws_iam_role_policy.kms_access[0]
}

# ─────────────────────────────────────────────────────────────────────────────
# Atlas Encryption at Rest
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_encryption_at_rest" "this" {
  project_id               = var.project_id
  enabled_for_search_nodes = var.enabled_for_search_nodes

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

  depends_on = [aws_iam_role_policy.kms_access, aws_kms_replica_key.atlas]
}
