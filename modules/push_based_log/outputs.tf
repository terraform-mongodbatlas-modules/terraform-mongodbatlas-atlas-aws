output "create_date" {
  value       = mongodbatlas_push_based_log_export.this.create_date
  description = "Date the push-based log export was created"
}

output "state" {
  value       = mongodbatlas_push_based_log_export.this.state
  description = "State of the push-based log export"
}

output "iam_role_name" {
  value       = local.role_name
  description = "Name of the IAM role used for push-based log export"
}

output "s3_bucket_arn" {
  value       = local.bucket_arn
  description = "ARN of the S3 bucket used for push-based log export"
}

output "s3_bucket_name" {
  value       = var.bucket_name
  description = "Name of the S3 bucket used for push-based log export"
}
