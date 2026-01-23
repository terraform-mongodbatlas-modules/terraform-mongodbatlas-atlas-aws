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
  description = "KMS key ID (only set if module-created)"
  value       = local.create_kms_key ? aws_kms_key.atlas[0].key_id : null
}

output "atlas_region" {
  description = "Normalized Atlas region format"
  value       = local.atlas_region
}

output "aws_region" {
  description = "AWS region format"
  value       = local.aws_region
}
