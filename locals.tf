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
}
