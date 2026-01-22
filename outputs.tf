output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-AWS features"
  value       = local.role_id
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = var.encryption.enabled ? "AWS" : "NONE"
}

output "export_bucket_id" {
  description = "Export bucket ID for backup schedule auto_export_enabled"
  value       = null # Implemented in t05-23
}

output "encryption" {
  description = "Encryption at rest configuration"
  value       = null # Implemented in t05-21
}

output "privatelink" {
  description = "PrivateLink endpoints per user key"
  value       = {} # Implemented in t05-22
}

output "privatelink_service_info" {
  description = "Atlas PrivateLink service info for BYOE pattern"
  value       = {} # Implemented in t05-22
}

output "backup_export" {
  description = "Backup export configuration"
  value       = null # Implemented in t05-23
}

output "resource_ids" {
  description = "All resource IDs for data source lookups"
  value = {
    role_id      = local.role_id
    iam_role_arn = local.iam_role_arn
  }
}
