locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_endpoints_single_region) > 0 || length(var.privatelink_byoe_regions) > 0
  skip_cloud_provider_access = (
    !var.encryption.enabled &&
    !var.backup_export.enabled &&
    local.privatelink_configured
  )

  # Cloud provider access: module-managed vs existing
  create_cloud_provider_access = var.cloud_provider_access.create && !local.skip_cloud_provider_access
  role_id = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].role_id
  ) : try(var.cloud_provider_access.existing.role_id, null)
  iam_role_arn = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].iam_role_arn
  ) : try(var.cloud_provider_access.existing.iam_role_arn, null)
  iam_role_name = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].iam_role_name
  ) : null

  # Encryption IAM role: dedicated or shared
  create_encryption_dedicated_role = var.encryption.enabled && var.encryption.iam_role.create
  encryption_role_id = local.create_encryption_dedicated_role ? (
    module.encryption_cloud_provider_access[0].role_id
  ) : local.role_id
  encryption_iam_role_name = local.create_encryption_dedicated_role ? (
    module.encryption_cloud_provider_access[0].iam_role_name
  ) : local.iam_role_name

  # Backup export IAM role: dedicated or shared
  create_backup_export_dedicated_role = var.backup_export.enabled && var.backup_export.iam_role.create
  backup_export_role_id = local.create_backup_export_dedicated_role ? (
    module.backup_export_cloud_provider_access[0].role_id
  ) : local.role_id
  backup_export_iam_role_name = local.create_backup_export_dedicated_role ? (
    module.backup_export_cloud_provider_access[0].iam_role_name
  ) : local.iam_role_name

  # Private endpoint regions: user-provided or default to encryption region
  encryption_default_region = coalesce(var.encryption.region, data.aws_region.current.id)
  encryption_private_endpoint_regions = (
    var.encryption.enabled && var.encryption.require_private_networking
    ) ? (
    length(var.encryption.private_endpoint_regions) > 0
    ? var.encryption.private_endpoint_regions
    : toset([local.encryption_default_region])
  ) : toset([])

  # PrivateLink: convert lists to maps for for_each
  # Multi-region: use region as key (guaranteed unique by validation)
  privatelink_endpoints_map = { for ep in var.privatelink_endpoints : ep.region => ep }
  # Single-region: use index as key (regions are same)
  privatelink_endpoints_single_region_map = { for idx, ep in var.privatelink_endpoints_single_region : tostring(idx) => ep }
  # Combined module-managed endpoints
  privatelink_module_managed = merge(local.privatelink_endpoints_map, local.privatelink_endpoints_single_region_map)
  # Include BYOE regions (minimal config for Atlas-side endpoint)
  privatelink_endpoints = merge(
    local.privatelink_module_managed,
    { for k, region in var.privatelink_byoe_regions : k => { region = region, subnet_ids = [], security_group = { create = false }, tags = {} } }
  )
  privatelink_module_calls = merge(
    local.privatelink_module_managed,
    { for k, region in var.privatelink_byoe_regions : k => { region = region, subnet_ids = [], security_group = { create = false }, tags = {} } if contains(keys(var.privatelink_byoe), k) }
  )
  # Enable regional mode only for multi-region pattern
  privatelink_all_regions = toset([for k, value in local.privatelink_endpoints : value.region])
  enable_regional_mode    = length(local.privatelink_all_regions) > 1
}
