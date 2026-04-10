output "bucket_name" {
  description = "S3 bucket name"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = local.bucket_arn
}

output "integration_ids" {
  description = "List of integration resource IDs"
  value       = mongodbatlas_log_integration.this[*].integration_id
}

output "expiration_days" {
  description = "S3 lifecycle expiration in days (0 = disabled, null = BYO bucket)"
  value       = local.create_bucket ? var.create_s3_bucket.expiration_days : null
}
