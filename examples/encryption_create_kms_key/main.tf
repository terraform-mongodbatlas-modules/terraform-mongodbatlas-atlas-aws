module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled = true
    create_kms_key = {
      enabled                 = true
      alias                   = "alias/atlas-encryption"
      deletion_window_in_days = 7
      enable_key_rotation     = true
    }
  }
}

output "encryption" {
  value = module.atlas_aws.encryption
}
