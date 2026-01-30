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
  purpose                       = "encrypt"
  iam_role_name                 = var.encryption.iam_role.name
  iam_role_path                 = var.encryption.iam_role.path
  iam_role_permissions_boundary = var.encryption.iam_role.permissions_boundary
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
  tags                       = var.aws_tags
  require_private_networking = local.encryption_require_private_networking

  depends_on = [module.cloud_provider_access, module.encryption_cloud_provider_access]
}

module "encryption_private_endpoint" {
  source   = "./modules/encryption_private_endpoint"
  for_each = local.encryption_private_endpoint_regions

  project_id = var.project_id
  region     = each.key

  depends_on = [module.encryption]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dedicated IAM role for backup export (when backup_export.iam_role.create = true)
# ─────────────────────────────────────────────────────────────────────────────

module "backup_export_cloud_provider_access" {
  count  = local.create_backup_export_dedicated_role ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "backup"
  iam_role_name                 = var.backup_export.iam_role.name
  iam_role_path                 = var.backup_export.iam_role.path
  iam_role_permissions_boundary = var.backup_export.iam_role.permissions_boundary
  tags                          = var.aws_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup Export to S3
# ─────────────────────────────────────────────────────────────────────────────

module "backup_export" {
  count  = var.backup_export.enabled ? 1 : 0
  source = "./modules/backup_export"

  project_id       = var.project_id
  atlas_role_id    = local.backup_export_role_id
  iam_role_name    = local.backup_export_iam_role_name
  bucket_name      = var.backup_export.bucket_name
  create_s3_bucket = var.backup_export.create_s3_bucket
  tags             = var.aws_tags

  depends_on = [module.cloud_provider_access, module.backup_export_cloud_provider_access]
}

# ─────────────────────────────────────────────────────────────────────────────
# PrivateLink
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count      = local.enable_regional_mode ? 1 : 0
  project_id = var.project_id
  enabled    = true
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each      = local.privatelink_endpoints
  project_id    = var.project_id
  provider_name = "AWS"
  region        = lower(replace(each.value.region, "_", "-")) # AWS format (us-east-1)
}

module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_module_calls

  project_id            = var.project_id
  region                = lower(replace(each.value.region, "_", "-")) # AWS format (us-east-1)
  private_link_id       = mongodbatlas_privatelink_endpoint.this[each.key].private_link_id
  endpoint_service_name = mongodbatlas_privatelink_endpoint.this[each.key].endpoint_service_name

  vpc_endpoint = {
    create     = contains(keys(local.privatelink_module_managed), each.key)
    subnet_ids = each.value.subnet_ids
  }
  byo_vpc_endpoint_id = try(var.privatelink_byoe[each.key].vpc_endpoint_id, null)

  security_group = {
    ids                 = try(each.value.security_group.ids, null)
    create              = try(each.value.security_group.create, true)
    name_prefix         = try(each.value.security_group.name_prefix, "atlas-privatelink-")
    inbound_cidr_blocks = try(each.value.security_group.inbound_cidr_blocks, null)
    inbound_source_sgs  = try(each.value.security_group.inbound_source_sgs, [])
    from_port           = try(each.value.security_group.from_port, 1024)
    to_port             = try(each.value.security_group.to_port, 65535)
  }

  tags = merge(var.aws_tags, each.value.tags)

  depends_on = [mongodbatlas_private_endpoint_regional_mode.this]
}
