locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_byoe_regions) > 0
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

  # PrivateLink: merge module-managed and BYOE regions
  # Key -> region mapping
  privatelink_key_region = merge(
    var.privatelink_byoe_regions,
    { for k, v in var.privatelink_endpoints : k => coalesce(v.region, k) }
  )
  privatelink_module_managed = toset(keys(var.privatelink_endpoints))
  privatelink_regions        = toset(values(local.privatelink_key_region))

  # Auto-enable regional mode for multi-region
  enable_regional_mode = length(local.privatelink_regions) > 1
}
