resource "aws_kms_key" "atlas" {
  description             = "Atlas Encryption at Rest"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  encryption = {
    enabled                  = true
    kms_key_arn              = aws_kms_key.atlas.arn
    private_endpoint_regions = [var.aws_region]
  }
}

output "encryption" {
  value = module.atlas_aws.encryption
}
