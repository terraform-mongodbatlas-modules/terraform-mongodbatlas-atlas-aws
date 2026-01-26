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
        id     = v.id
        status = v.status
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
