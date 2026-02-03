module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  privatelink_endpoints = [
    {
      region     = var.aws_region
      subnet_ids = var.subnet_ids
    }
  ]
}

output "privatelink" {
  value = module.atlas_aws.privatelink
}
