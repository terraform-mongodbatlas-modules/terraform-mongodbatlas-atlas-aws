locals {
  # Dynamic derivation: skip cloud_provider_access when only privatelink is configured
  privatelink_configured = length(var.privatelink_endpoints) > 0 || length(var.privatelink_endpoints_single_region) > 0 || length(var.privatelink_byoe_regions) > 0
  skip_cloud_provider_access = (
    !var.encryption.enabled &&
    !var.backup_export.enabled &&
    !var.log_integration.enabled &&
    local.privatelink_configured
  )

  # Cloud provider access: module-managed vs existing
  create_cloud_provider_access = var.cloud_provider_access.create && !local.skip_cloud_provider_access
  skip_iam_policy_attachments  = var.cloud_provider_access.skip_iam_policy_attachments
  role_id = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].role_id
  ) : try(var.cloud_provider_access.existing.role_id, null)
  iam_role_arn = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].iam_role_arn
  ) : try(var.cloud_provider_access.existing.iam_role_arn, null)
  iam_role_name_output = local.create_cloud_provider_access ? (
    module.cloud_provider_access[0].iam_role_name
  ) : try(regex("role/(?:.+/)?(?P<name>[^/]+)$", var.cloud_provider_access.existing.iam_role_arn)["name"], null)
  iam_role_name = local.skip_iam_policy_attachments ? null : local.iam_role_name_output

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

  # Log integration IAM role: dedicated or shared
  create_log_integration_dedicated_role = var.log_integration.enabled && var.log_integration.iam_role.create
  log_integration_role_id = local.create_log_integration_dedicated_role ? (
    module.log_integration_cloud_provider_access[0].role_id
  ) : local.role_id
  log_integration_iam_role_name = local.create_log_integration_dedicated_role ? (
    module.log_integration_cloud_provider_access[0].iam_role_name
  ) : local.iam_role_name

  # Private endpoint regions: inferred from presence of private_endpoint_regions
  encryption_private_endpoint_regions = (
    var.encryption.enabled && length(var.encryption.private_endpoint_regions) > 0
    ? toset([for r in var.encryption.private_endpoint_regions : lower(replace(r, "_", "-"))])
    : toset([])
  )
  encryption_require_private_networking = length(local.encryption_private_endpoint_regions) > 0

  # PrivateLink: convert lists to maps for for_each
  # Primary entries: create Atlas endpoint (service_region == null)
  privatelink_primary_map = {
    for ep in var.privatelink_endpoints :
    lower(replace(ep.region, "_", "-")) => ep
    if ep.service_region == null
  }
  # Cross-region entries: reuse Atlas endpoint from service_region
  privatelink_cross_region_map = {
    for ep in var.privatelink_endpoints :
    lower(replace(ep.region, "_", "-")) => ep
    if ep.service_region != null
  }
  # Single-region: use index as key (regions are same)
  privatelink_endpoints_single_region_map = { for idx, ep in var.privatelink_endpoints_single_region : tostring(idx) => ep }
  # Combined module-managed endpoints
  privatelink_module_managed = merge(local.privatelink_primary_map, local.privatelink_endpoints_single_region_map, local.privatelink_cross_region_map)
  # Atlas-side endpoints: primary + single-region + BYOE (not cross-region)
  privatelink_atlas_endpoints = merge(
    local.privatelink_primary_map,
    local.privatelink_endpoints_single_region_map,
    { for k, v in var.privatelink_byoe_regions : k => { region = v.region, subnet_ids = [], security_group = { create = false }, tags = {} } }
  )
  # BYOE module calls split into same-region and cross-region
  _privatelink_byoe_same_region = {
    for k, v in var.privatelink_byoe : k => {
      region         = var.privatelink_byoe_regions[k].region
      subnet_ids     = []
      security_group = { create = false }
      tags           = {}
    } if v.service_region_key == null && contains(keys(var.privatelink_byoe_regions), k)
  }
  _privatelink_byoe_cross_region = {
    for k, v in var.privatelink_byoe : k => {
      region             = v.region
      service_region_key = v.service_region_key
      subnet_ids         = []
      security_group     = { create = false }
      tags               = {}
    } if v.service_region_key != null
  }
  privatelink_module_calls = merge(
    local.privatelink_module_managed,
    local._privatelink_byoe_same_region,
    local._privatelink_byoe_cross_region,
  )
  # Normalized AWS region per endpoint key (all entries, not just Atlas endpoints)
  _privatelink_aws_region = {
    for k, v in merge(local.privatelink_atlas_endpoints, local.privatelink_cross_region_map, local._privatelink_byoe_cross_region) :
    k => lower(replace(v.region, "_", "-"))
  }
  # Supported remote regions per Atlas endpoint (module-managed + BYOE)
  _privatelink_supported_remote_regions = merge(
    {
      for k in keys(local.privatelink_primary_map) :
      k => [
        for ep in var.privatelink_endpoints :
        upper(replace(ep.region, "-", "_"))
        if ep.service_region != null && lower(replace(ep.service_region, "_", "-")) == k
      ]
    },
    {
      for k, v in var.privatelink_byoe_regions :
      k => [for r in v.supported_remote_regions : upper(replace(r, "-", "_"))]
    }
  )
  # Lookup from module-call key to Atlas endpoint key
  _privatelink_atlas_endpoint_key = {
    for k, v in local.privatelink_module_calls : k => (
      try(v.service_region_key, null) != null ? v.service_region_key :
      try(v.service_region, null) != null ? lower(replace(v.service_region, "_", "-")) :
      k
    )
  }
  # Regional mode: count only Atlas service regions (primary + BYOE), not cross-region VPC endpoints
  _privatelink_atlas_service_regions = { for k, v in local.privatelink_atlas_endpoints : k => lower(replace(v.region, "_", "-")) }
  privatelink_all_regions            = toset(values(local._privatelink_atlas_service_regions))
  enable_regional_mode               = length(local.privatelink_all_regions) > 1
}
