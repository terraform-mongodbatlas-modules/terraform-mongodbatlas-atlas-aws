module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  log_integration = {
    enabled = true
    create_s3_bucket = {
      enabled       = true
      name_prefix   = var.bucket_name_prefix
      force_destroy = var.force_destroy
    }
    integrations = [
      { log_types = ["MONGOD"], prefix_path = "operational" },
      { log_types = ["MONGOD_AUDIT"], prefix_path = "audit" },
    ]
  }

  aws_tags = var.aws_tags
}

output "log_integration" {
  value = module.atlas_aws.log_integration
}
