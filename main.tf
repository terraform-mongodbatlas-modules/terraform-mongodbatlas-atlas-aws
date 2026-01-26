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

  kms_key_arn    = var.encryption.kms_key_arn
  region         = var.encryption.region
  create_kms_key = var.encryption.create_kms_key
  tags           = var.aws_tags

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
# PrivateLink
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count      = local.enable_regional_mode ? 1 : 0
  project_id = var.project_id
  enabled    = true
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each      = local.privatelink_all
  project_id    = var.project_id
  provider_name = "AWS"
  region        = local.to_aws_region[each.key]
}

module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_all

  project_id            = var.project_id
  region                = local.to_aws_region[each.key]
  private_link_id       = mongodbatlas_privatelink_endpoint.this[each.key].private_link_id
  endpoint_service_name = mongodbatlas_privatelink_endpoint.this[each.key].endpoint_service_name

  create_vpc_endpoint      = contains(keys(local.privatelink_module_managed), each.key)
  subnet_ids               = each.value.subnet_ids
  existing_vpc_endpoint_id = try(var.privatelink_byoe[each.key].vpc_endpoint_id, null)

  security_group_ids                 = try(each.value.security_group.ids, null)
  create_security_group              = try(each.value.security_group.create, true)
  security_group_name_prefix         = try(each.value.security_group.name_prefix, "atlas-privatelink-")
  security_group_inbound_cidr_blocks = try(each.value.security_group.inbound_cidr_blocks, null)
  security_group_inbound_source_sgs  = try(each.value.security_group.inbound_source_sgs, [])
  security_group_from_port           = try(each.value.security_group.from_port, 1024)
  security_group_to_port             = try(each.value.security_group.to_port, 65535)

  tags = merge(var.aws_tags, each.value.tags)

  depends_on = [mongodbatlas_private_endpoint_regional_mode.this]
}
