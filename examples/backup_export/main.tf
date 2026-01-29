module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  backup_export = {
    enabled = true
    create_s3_bucket = {
      enabled       = true
      name          = var.bucket_name
      force_destroy = var.force_destroy
    }
  }
}

output "backup_export" {
  value = module.atlas_aws.backup_export
}
