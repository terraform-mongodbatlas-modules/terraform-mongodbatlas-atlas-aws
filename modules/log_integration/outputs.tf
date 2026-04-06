output "bucket_name" {
  description = "S3 bucket name"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = local.bucket_arn
}

output "integration_ids" {
  description = "Map of integration index to resource ID"
  value       = { for k, v in mongodbatlas_log_integration.this : k => v.integration_id }
}
