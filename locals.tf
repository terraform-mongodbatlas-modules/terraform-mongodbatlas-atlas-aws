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

  # Encryption IAM role: dedicated or shared
  create_encryption_dedicated_role = var.encryption.enabled && var.encryption.iam_role.create
  encryption_role_id = local.create_encryption_dedicated_role ? (
    module.encryption_cloud_provider_access[0].role_id
  ) : local.role_id
  encryption_iam_role_name = local.create_encryption_dedicated_role ? (
    module.encryption_cloud_provider_access[0].iam_role_name
  ) : local.iam_role_name

  # Private endpoint regions: user-provided or default to encryption region
  # We compute the default region at root level to avoid unknown for_each keys
  encryption_default_region = coalesce(var.encryption.region, data.aws_region.current.id)
  encryption_private_endpoint_regions = (
    var.encryption.enabled && var.encryption.require_private_networking
    ) ? (
    length(var.encryption.private_endpoint_regions) > 0
    ? var.encryption.private_endpoint_regions
    : toset([local.encryption_default_region])
  ) : toset([])
}
