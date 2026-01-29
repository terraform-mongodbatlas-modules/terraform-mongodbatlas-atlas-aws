output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-AWS features"
  value       = local.role_id
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = var.encryption.enabled ? "AWS" : "NONE"
}

output "encryption" {
  description = "Encryption at rest status and configuration"
  value = var.encryption.enabled ? {
    valid       = module.encryption[0].valid
    kms_key_arn = module.encryption[0].kms_key_arn
    kms_key_id  = module.encryption[0].kms_key_id
    private_endpoints = {
      for k, v in module.encryption_private_endpoint :
      k => {
        id            = v.id
        status        = v.status
        error_message = v.error_message
      }
    }
  } : null
}

output "resource_ids" {
  description = "All resource IDs for data source lookups"
  value = {
    role_id      = local.role_id
    iam_role_arn = local.iam_role_arn
    kms_key_arn  = try(module.encryption[0].kms_key_arn, null)
  }
}

output "privatelink" {
  description = "PrivateLink status per endpoint key"
  value = {
    for key, pl in module.privatelink : key => {
      region                      = local.privatelink_module_calls[key].region
      atlas_private_link_id       = pl.atlas_private_link_id
      atlas_endpoint_service_name = pl.atlas_endpoint_service_name
      vpc_endpoint_id             = pl.vpc_endpoint_id
      status                      = pl.status
      error_message               = pl.error_message
      security_group_id           = pl.security_group_id
    }
  }
}

output "privatelink_service_info" {
  description = "Atlas PrivateLink service info for BYOE pattern"
  value = {
    for key, ep in mongodbatlas_privatelink_endpoint.this : key => {
      region                      = ep.region
      atlas_private_link_id       = ep.private_link_id
      atlas_endpoint_service_name = ep.endpoint_service_name
      status                      = ep.status
    }
  }
}

output "regional_mode_enabled" {
  description = "Whether private endpoint regional mode is enabled"
  value       = local.enable_regional_mode
}

output "export_bucket_id" {
  description = "Export bucket ID for backup schedule auto_export_enabled"
  value       = var.backup_export.enabled ? module.backup_export[0].export_bucket_id : null
}

output "backup_export" {
  description = "Backup export configuration"
  value = var.backup_export.enabled ? {
    export_bucket_id = module.backup_export[0].export_bucket_id
    bucket_name      = module.backup_export[0].bucket_name
    bucket_arn       = module.backup_export[0].bucket_arn
  } : null
}
