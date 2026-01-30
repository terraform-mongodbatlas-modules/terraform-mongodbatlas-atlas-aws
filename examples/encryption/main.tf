module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled = true
    create_kms_key = {
      enabled             = true
      alias               = "alias/atlas-encryption"
      enable_key_rotation = true
    }
  }

  aws_tags = {
    Environment = "production"
    Module      = "atlas-aws"
  }
}

output "encryption" {
  value = module.atlas_aws.encryption
}
