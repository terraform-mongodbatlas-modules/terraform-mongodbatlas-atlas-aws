output "role_id" {
  description = "Atlas role ID for reuse with other Atlas-AWS features"
  value       = local.role_id
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = var.encryption.enabled ? "AWS" : "NONE"
}

output "resource_ids" {
  description = "All resource IDs for data source lookups"
  value = {
    role_id      = local.role_id
    iam_role_arn = local.iam_role_arn
  }
}
