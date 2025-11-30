output "aws_kms_config_valid" {
  value = mongodbatlas_encryption_at_rest.this.aws_kms_config == null ? null : mongodbatlas_encryption_at_rest.this.aws_kms_config[0].valid
}

output "private_endpoint_error_message" {
  value = var.private_networking.create_atlas_private_endpoint ? mongodbatlas_encryption_at_rest_private_endpoint.this[0].error_message : ""
}

output "private_endpoint_connection_name" {
  value = var.private_networking.create_atlas_private_endpoint ? mongodbatlas_encryption_at_rest_private_endpoint.this[0].private_endpoint_connection_name : ""
}

output "private_endpoint_status" {
  value = var.private_networking.create_atlas_private_endpoint ? mongodbatlas_encryption_at_rest_private_endpoint.this[0].status : ""
}

output "kms_key_arn" {
  value       = var.create_kms_key ? aws_kms_key.this[0].arn : null
  description = "ARN of the created KMS key (null if not created)"
}

output "kms_key_id" {
  value       = var.create_kms_key ? aws_kms_key.this[0].key_id : null
  description = "ID of the created KMS key (null if not created)"
}

output "iam_role_arn" {
  value       = var.create_kms_iam_role ? aws_iam_role.kms[0].arn : null
  description = "ARN of the created IAM role (null if not created)"
}

output "kms_vpc_endpoint_id" {
  value       = var.private_networking.create_aws_kms_vpc_endpoint ? aws_vpc_endpoint.kms[0].id : null
  description = "ID of the KMS VPC endpoint (null if not created)"
}

output "security_group_id" {
  value       = var.private_networking.create_security_group ? aws_security_group.kms_endpoint[0].id : null
  description = "ID of the created security group (null if not created)"
}
