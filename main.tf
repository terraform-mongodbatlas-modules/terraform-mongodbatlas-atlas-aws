data "aws_region" "current" {}

module "cloud_provider_access" {
  count  = local.create_cloud_provider_access ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "shared"
  iam_role_name                 = var.cloud_provider_access.iam_role_name
  iam_role_path                 = var.cloud_provider_access.iam_role_path
  iam_role_permissions_boundary = var.cloud_provider_access.iam_role_permissions_boundary
  tags                          = var.aws_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Dedicated IAM role for encryption (when encryption.iam_role.create = true)
# ─────────────────────────────────────────────────────────────────────────────

module "encryption_cloud_provider_access" {
  count  = local.create_encryption_dedicated_role ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "encryption"
  iam_role_name                 = try(var.encryption.iam_role.name, null)
  iam_role_path                 = try(var.encryption.iam_role.path, "/")
  iam_role_permissions_boundary = try(var.encryption.iam_role.permissions_boundary, null)
  tags                          = var.aws_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Encryption at Rest with AWS KMS
# ─────────────────────────────────────────────────────────────────────────────

module "encryption" {
  count  = var.encryption.enabled ? 1 : 0
  source = "./modules/encryption"

  project_id    = var.project_id
  role_id       = local.encryption_role_id
  iam_role_name = local.encryption_iam_role_name

  kms_key_arn                = var.encryption.kms_key_arn
  region                     = var.encryption.region
  create_kms_key             = var.encryption.create_kms_key
  require_private_networking = var.encryption.require_private_networking
  tags                       = var.aws_tags

  depends_on = [module.cloud_provider_access, module.encryption_cloud_provider_access]
}

module "encryption_private_endpoint" {
  source   = "./modules/encryption_private_endpoint"
  for_each = local.encryption_private_endpoint_regions

  project_id = var.project_id
  region     = each.key

  depends_on = [module.encryption]
}
