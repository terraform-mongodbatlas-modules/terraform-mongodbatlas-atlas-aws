output "access_setup_aws_config" {
  value     = try(mongodbatlas_cloud_provider_access_setup.this[0].aws_config, null)
  sensitive = true
}

output "access_setup_created_date" {
  value = try(mongodbatlas_cloud_provider_access_setup.this[0].created_date, null)
}

output "access_setup_last_updated_date" {
  value = try(mongodbatlas_cloud_provider_access_setup.this[0].last_updated_date, null)
}

output "role_id" {
  value = try(mongodbatlas_cloud_provider_access_authorization.this[0].role_id, null)
}

output "access_authorization_authorized_date" {
  value = try(mongodbatlas_cloud_provider_access_authorization.this[0].authorized_date, null)
}

output "access_authorization_feature_usages" {
  value = try(mongodbatlas_cloud_provider_access_authorization.this[0].feature_usages, null)
}

output "aws_iam_role_arn" {
  value = local.aws_iam_role_arn
}

output "push_based_log_export" {
  value = try(module.push_based_log_export[0], null)
}

output "encryption_at_rest" {
  value = try({
    aws_kms_config_valid             = module.encryption_at_rest[0].aws_kms_config_valid
    private_endpoint_error_message   = module.encryption_at_rest[0].private_endpoint_error_message
    private_endpoint_connection_name = module.encryption_at_rest[0].private_endpoint_connection_name
    private_endpoint_status          = module.encryption_at_rest[0].private_endpoint_status
    kms_key_arn                      = module.encryption_at_rest[0].kms_key_arn
    kms_key_id                       = module.encryption_at_rest[0].kms_key_id
    iam_role_arn                     = module.encryption_at_rest[0].iam_role_arn
    kms_vpc_endpoint_id              = module.encryption_at_rest[0].kms_vpc_endpoint_id
  }, null)
}

output "privatelink" {
  value = try(module.privatelink[0], null)
}
