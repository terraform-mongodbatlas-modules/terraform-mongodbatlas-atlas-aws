module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  privatelink_endpoints = [
    { region = "us-east-1", subnet_ids = var.subnet_ids_us_east_1 },
    { region = "us-west-2", subnet_ids = var.subnet_ids_us_west_2 },
  ]
}

output "privatelink" {
  value = module.atlas_aws.privatelink
}

output "regional_mode_enabled" {
  value = module.atlas_aws.regional_mode_enabled
}
