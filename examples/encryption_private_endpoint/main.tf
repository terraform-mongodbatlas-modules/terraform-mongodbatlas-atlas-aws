resource "aws_kms_key" "atlas" {
  description             = "Atlas Encryption at Rest"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled                    = true
    kms_key_arn                = aws_kms_key.atlas.arn
    require_private_networking = true
    # private_endpoint_regions defaults to the encryption region (provider region)
  }
}

output "encryption" {
  value = module.atlas_aws.encryption
}
