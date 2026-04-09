module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  cloud_provider_access = {
    create                      = false
    skip_iam_policy_attachments = true
    existing = {
      role_id      = var.atlas_role_id
      iam_role_arn = var.atlas_iam_role_arn
    }
  }

  encryption = {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  backup_export = {
    enabled     = true
    bucket_name = var.backup_bucket_name
  }

  log_integration = {
    enabled     = true
    bucket_name = var.log_bucket_name
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
    ]
  }
}

output "role_id" {
  value = module.atlas_aws.role_id
}

output "resource_ids" {
  value = module.atlas_aws.resource_ids
}
