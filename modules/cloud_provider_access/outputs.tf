output "role_id" {
  description = "Atlas role ID for use with encryption, backup export, and other Atlas-AWS features."
  value       = mongodbatlas_cloud_provider_access_authorization.this.role_id
}

output "iam_role_arn" {
  description = "ARN of the IAM role that Atlas assumes."
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for attaching additional policies."
  value       = aws_iam_role.this.name
}

output "authorized_date" {
  description = "Date when the cloud provider access was authorized."
  value       = mongodbatlas_cloud_provider_access_authorization.this.authorized_date
}

output "feature_usages" {
  description = "List of Atlas features using this cloud provider access role."
  value       = mongodbatlas_cloud_provider_access_authorization.this.feature_usages
}

output "atlas_aws_account_arn" {
  description = "Atlas AWS account ARN (for reference in custom IAM policies)."
  value       = mongodbatlas_cloud_provider_access_setup.this.aws_config[0].atlas_aws_account_arn
}

output "atlas_assumed_role_external_id" {
  description = "External ID for STS AssumeRole (for reference in custom IAM policies)."
  value       = mongodbatlas_cloud_provider_access_setup.this.aws_config[0].atlas_assumed_role_external_id
}
