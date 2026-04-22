module "cloud_provider_access" {
  count  = local.create_cloud_provider_access ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "shared"
  iam_role_name                 = var.cloud_provider_access.iam_role_name
  iam_role_path                 = var.cloud_provider_access.iam_role_path
  iam_role_permissions_boundary = var.cloud_provider_access.iam_role_permissions_boundary
  tags                          = var.aws_tags
  timeouts                      = var.timeouts
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
  timeouts                      = var.timeouts
}

# ─────────────────────────────────────────────────────────────────────────────
# Encryption at Rest with AWS KMS
# ─────────────────────────────────────────────────────────────────────────────

module "encryption" {
  count  = var.encryption.enabled ? 1 : 0
  source = "./modules/encryption"

  project_id                  = var.project_id
  role_id                     = local.encryption_role_id
  iam_role_name               = local.encryption_iam_role_name
  skip_iam_policy_attachments = !local.create_encryption_dedicated_role && local.skip_iam_policy_attachments

  kms_key_arn                = var.encryption.kms_key_arn
  region                     = var.encryption.region
  create_kms_key             = var.encryption.create_kms_key
  tags                       = var.aws_tags
  require_private_networking = local.encryption_require_private_networking
  enabled_for_search_nodes   = var.encryption.enabled_for_search_nodes
  timeouts                   = var.timeouts

  depends_on = [module.cloud_provider_access, module.encryption_cloud_provider_access]
}

module "encryption_private_endpoint" {
  source   = "./modules/encryption_private_endpoint"
  for_each = local.encryption_private_endpoint_regions

  project_id = var.project_id
  region     = each.key
  timeouts   = var.timeouts

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
  timeouts                      = var.timeouts
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup Export to S3
# ─────────────────────────────────────────────────────────────────────────────

module "backup_export" {
  count  = var.backup_export.enabled ? 1 : 0
  source = "./modules/backup_export"

  project_id                  = var.project_id
  atlas_role_id               = local.backup_export_role_id
  iam_role_name               = local.backup_export_iam_role_name
  skip_iam_policy_attachments = !local.create_backup_export_dedicated_role && local.skip_iam_policy_attachments
  bucket_name                 = var.backup_export.bucket_name
  create_s3_bucket            = var.backup_export.create_s3_bucket
  tags                        = var.aws_tags
  timeouts                    = var.timeouts

  depends_on = [module.cloud_provider_access, module.backup_export_cloud_provider_access]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dedicated IAM role for log integration (when log_integration.iam_role.create = true)
# ─────────────────────────────────────────────────────────────────────────────

module "log_integration_cloud_provider_access" {
  count  = local.create_log_integration_dedicated_role ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "logs"
  iam_role_name                 = var.log_integration.iam_role.name
  iam_role_path                 = var.log_integration.iam_role.path
  iam_role_permissions_boundary = var.log_integration.iam_role.permissions_boundary
  tags                          = var.aws_tags
  timeouts                      = var.timeouts
}

# ─────────────────────────────────────────────────────────────────────────────
# Log Integration (S3)
# ─────────────────────────────────────────────────────────────────────────────

module "log_integration" {
  count  = var.log_integration.enabled ? 1 : 0
  source = "./modules/log_integration"

  project_id                  = var.project_id
  atlas_role_id               = local.log_integration_role_id
  iam_role_name               = local.log_integration_iam_role_name
  skip_iam_policy_attachments = !local.create_log_integration_dedicated_role && local.skip_iam_policy_attachments
  bucket_name                 = var.log_integration.bucket_name
  create_s3_bucket            = var.log_integration.create_s3_bucket
  integrations                = var.log_integration.integrations
  kms_key                     = var.log_integration.kms_key
  kms_key_skip_iam_policy     = var.log_integration.kms_key_skip_iam_policy
  tags                        = merge(var.aws_tags, var.log_integration.tags)
  timeouts                    = var.timeouts

  depends_on = [module.cloud_provider_access, module.log_integration_cloud_provider_access]
}

# ─────────────────────────────────────────────────────────────────────────────
# PrivateLink
# ─────────────────────────────────────────────────────────────────────────────

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count      = local.enable_regional_mode ? 1 : 0
  project_id = var.project_id
  enabled    = true

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each                 = local.privatelink_atlas_endpoints
  project_id               = var.project_id
  provider_name            = "AWS"
  region                   = lower(replace(each.value.region, "_", "-"))
  supported_remote_regions = try(local._privatelink_supported_remote_regions[each.key], [])

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

# VPC/subnet lookups live here (not in the submodule) because the privatelink
# module call has `depends_on = [mongodbatlas_private_endpoint_regional_mode.this]`.
# When that dependency has pending changes Terraform defers every data source
# read inside the module, turning vpc_id and cidr_block into "known after apply".
# Those feed ForceNew attributes on aws_security_group, aws_security_group_rule,
# and aws_vpc_endpoint, causing unnecessary destroy/recreate cycles.
# Reading at root scope avoids deferral; results are passed as var.vpc_id and
# var.vpc_cidr_block. See: https://github.com/hashicorp/terraform/issues/26383
data "aws_subnet" "privatelink" {
  for_each = { for k, v in local.privatelink_module_managed : k => v.subnet_ids[0] }
  id       = each.value
  region   = local._privatelink_aws_region[each.key]
}

data "aws_vpc" "privatelink" {
  for_each = data.aws_subnet.privatelink
  id       = each.value.vpc_id
  region   = local._privatelink_aws_region[each.key]
}

module "privatelink" {
  source   = "./modules/privatelink"
  for_each = local.privatelink_module_calls

  project_id            = var.project_id
  region                = local._privatelink_aws_region[each.key]
  private_link_id       = mongodbatlas_privatelink_endpoint.this[local._privatelink_atlas_endpoint_key[each.key]].private_link_id
  endpoint_service_name = mongodbatlas_privatelink_endpoint.this[local._privatelink_atlas_endpoint_key[each.key]].endpoint_service_name
  service_region        = try(each.value.service_region, null)

  vpc_endpoint = {
    create     = contains(keys(local.privatelink_module_managed), each.key)
    subnet_ids = each.value.subnet_ids
  }
  byo_vpc_endpoint_id = try(var.privatelink_byo_service[each.key].vpc_endpoint_id, null)
  vpc_id              = try(data.aws_subnet.privatelink[each.key].vpc_id, null)
  vpc_cidr_block      = try(data.aws_vpc.privatelink[each.key].cidr_block, null)

  security_group = {
    ids                 = try(each.value.security_group.ids, null)
    create              = try(each.value.security_group.create, true)
    name_prefix         = try(each.value.security_group.name_prefix, "atlas-privatelink-")
    inbound_cidr_blocks = try(each.value.security_group.inbound_cidr_blocks, null)
    inbound_source_sgs  = try(each.value.security_group.inbound_source_sgs, [])
    from_port           = try(each.value.security_group.from_port, 1024)
    to_port             = try(each.value.security_group.to_port, 65535)
  }

  tags     = merge(var.aws_tags, each.value.tags)
  timeouts = var.timeouts

  depends_on = [mongodbatlas_private_endpoint_regional_mode.this]
}
