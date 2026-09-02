output "valid" {
  description = "Whether the encryption configuration is valid"
  value       = mongodbatlas_encryption_at_rest.this.aws_kms_config[0].valid
}

output "encryption_at_rest_provider" {
  description = "Value for cluster's encryption_at_rest_provider attribute"
  value       = "AWS"
}

output "project_id" {
  description = "Project ID for private endpoint dependencies"
  value       = var.project_id
}

output "kms_key_arn" {
  description = "KMS key ARN (user-provided or module-created)"
  value       = local.kms_key_arn
}

output "kms_key_id" {
  description = "KMS key ID (user-provided or module-created)"
  value       = local.kms_key_id
}

output "kms_replica_key_arns" {
  description = "Regional KMS replica key ARNs keyed by AWS region (module-managed multi-region keys only)"
  value       = { for region, replica in aws_kms_replica_key.atlas : region => replica.arn }
}

output "atlas_region" {
  description = "Normalized Atlas region format"
  value       = local.atlas_region
}

output "aws_region" {
  description = "AWS region format"
  value       = local.aws_region
}

output "enabled_for_search_nodes" {
  description = "Whether encryption at rest is enabled for dedicated search nodes"
  value       = mongodbatlas_encryption_at_rest.this.enabled_for_search_nodes
}

output "iam_propagation" {
  description = "IAM wait before Atlas encryption at rest. Null when skip_iam_policy_attachments is true."
  value = var.skip_iam_policy_attachments ? null : {
    create_duration = time_sleep.iam_propagation[0].create_duration
    trigger_keys    = sort(keys(time_sleep.iam_propagation[0].triggers))
  }
}
