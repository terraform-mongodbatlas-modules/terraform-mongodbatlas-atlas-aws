# Phase 1: Get endpoint service info from Atlas
module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  privatelink_byoe_regions = {
    primary = "us-east-1"
  }

  # Phase 2: Uncomment after creating VPC endpoint externally
  # privatelink_byoe = {
  #   primary = { vpc_endpoint_id = "vpce-0123456789abcdef0" }
  # }
}

# Phase 1 output: Use this to create VPC endpoint externally
output "privatelink_service_info" {
  value = module.atlas_aws.privatelink_service_info
}

output "privatelink" {
  value = module.atlas_aws.privatelink
}
