locals {
  # Shared cloud provider access is needed for: push_based_log (without own role), encryption (without own IAM role)
  needs_shared_cloud_provider_access = (var.push_based_log_export.enabled && !var.push_based_log_export.create_iam_role) || (var.encryption_at_rest.enabled && !var.encryption_at_rest.create_kms_iam_role)
  has_existing_aws_iam_role          = var.existing_aws_iam_role.enabled
  aws_iam_role_arn                   = local.has_existing_aws_iam_role ? var.existing_aws_iam_role.arn : try(aws_iam_role.this[0].arn, null)
  aws_iam_role_name_from_arn         = local.aws_iam_role_arn != null ? split("/", local.aws_iam_role_arn)[length(split("/", local.aws_iam_role_arn)) - 1] : null
}

resource "mongodbatlas_cloud_provider_access_setup" "this" {
  count = local.needs_shared_cloud_provider_access ? 1 : 0

  project_id    = var.project_id
  provider_name = "AWS"
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  count = local.needs_shared_cloud_provider_access ? 1 : 0

  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.this[0].role_id

  aws {
    iam_assumed_role_arn = local.aws_iam_role_arn
  }
}

module "encryption_at_rest" {
  source = "./modules/encryption_at_rest"
  count  = var.encryption_at_rest.enabled ? 1 : 0

  project_id          = var.project_id
  atlas_region        = var.atlas_region
  create_kms_key      = var.encryption_at_rest.create_kms_key
  create_kms_iam_role = var.encryption_at_rest.create_kms_iam_role

  # When using shared IAM role (create_kms_iam_role = false), pass existing role name and atlas_role_id
  existing_aws_iam_role_name = var.encryption_at_rest.create_kms_iam_role ? null : local.aws_iam_role_name_from_arn
  atlas_role_id              = var.encryption_at_rest.create_kms_iam_role ? null : try(mongodbatlas_cloud_provider_access_authorization.this[0].role_id, null)

  # When using existing KMS key
  aws_kms_key_arn = var.encryption_at_rest.aws_kms_key_arn

  # When creating KMS key and/or IAM role
  kms_key_alias       = var.encryption_at_rest.kms_key_alias
  kms_key_description = var.encryption_at_rest.kms_key_description
  aws_iam_role_name   = var.encryption_at_rest.aws_iam_role_name

  # Common settings
  enabled_for_search_nodes = var.encryption_at_rest.enabled_for_search_nodes
  private_networking       = var.encryption_at_rest.private_networking
  aws_tags                 = var.aws_tags

  # Adding an explicit dependency for the authorization to ensure the role_id has been authorized
  # Since the role_id from the authorization comes from setup resource Terraform doesn't infer this by default
  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

module "push_based_log_export" {
  source = "./modules/push_based_log"
  count  = var.push_based_log_export.enabled ? 1 : 0

  project_id = var.project_id

  # IAM role configuration
  create_iam_role        = var.push_based_log_export.create_iam_role
  aws_iam_role_name      = var.push_based_log_export.aws_iam_role_name
  existing_iam_role_name = var.push_based_log_export.create_iam_role ? null : local.aws_iam_role_name_from_arn
  atlas_role_id          = var.push_based_log_export.create_iam_role ? null : try(mongodbatlas_cloud_provider_access_authorization.this[0].role_id, null)

  # S3 bucket configuration
  bucket_name        = var.push_based_log_export.bucket_name
  create_s3_bucket   = var.push_based_log_export.create_s3_bucket
  prefix_path        = var.push_based_log_export.prefix_path
  bucket_policy_name = var.push_based_log_export.bucket_policy_name
  timeouts           = var.push_based_log_export.timeouts
  aws_tags           = var.aws_tags

  # Adding an explicit dependency for the authorization to ensure the role_id has been authorized
  # Since the role_id from the authorization comes from setup resource Terraform doesn't infer this by default
  depends_on = [mongodbatlas_cloud_provider_access_authorization.this]
}

module "privatelink" {
  source = "./modules/privatelink"
  count  = var.privatelink.enabled ? 1 : 0

  project_id                         = var.project_id
  atlas_region                       = var.atlas_region
  create_vpc_endpoint                = var.privatelink.create_vpc_endpoint
  existing_vpc_endpoint_id           = var.privatelink.existing_vpc_endpoint_id
  subnet_ids                         = var.privatelink.subnet_ids
  security_group_ids                 = var.privatelink.security_group_ids
  create_security_group              = var.privatelink.create_security_group
  security_group_inbound_cidr_blocks = var.privatelink.security_group_inbound_cidr_blocks
  security_group_name_prefix         = var.privatelink.security_group_name_prefix
  aws_tags                           = var.privatelink.tags
}

module "database_user_iam_role" {
  source = "./modules/database_user_iam_role"
  count  = var.aws_iam_role_db_admin.enabled ? 1 : 0

  project_id        = var.project_id
  existing_role_arn = var.aws_iam_role_db_admin.role_arn
  description       = var.aws_iam_role_db_admin.description
  labels            = var.aws_iam_role_db_admin.labels
  roles = [{
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
    },
    {
      role_name     = "atlasAdmin"
      database_name = "admin"
  }]
}
