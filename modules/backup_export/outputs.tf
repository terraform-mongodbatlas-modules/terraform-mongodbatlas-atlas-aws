output "export_bucket_id" {
  description = "Atlas export bucket ID for backup schedule auto_export_enabled"
  value       = mongodbatlas_cloud_backup_snapshot_export_bucket.this.export_bucket_id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = local.bucket_arn
}

output "expiration_days" {
  description = "S3 lifecycle expiration in days (0 = disabled, null = BYO bucket)"
  value       = local.create_bucket ? var.create_s3_bucket.expiration_days : null
}
