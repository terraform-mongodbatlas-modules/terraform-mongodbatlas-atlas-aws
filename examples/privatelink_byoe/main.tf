# BYOE (Bring Your Own Endpoint) pattern
# 
# For BYOE, we use a two-step approach:
# Step 1: Root module creates Atlas-side PrivateLink endpoint and exposes service info
# Step 2: User-managed AWS VPC Endpoint references the Atlas service info (see below)
#
# Note: Step 2 (aws_vpc_endpoint.custom) depends on Step 1 output (privatelink_service_info)

# Step 1: Configure Atlas PrivateLink with BYOE regions

locals {
  ep1 = "ep1"
}

module "atlas_aws" {
  source = "../../"

  project_id = var.project_id

  # BYOE: provide your own VPC endpoint ID
  privatelink_byoe = {
    (local.ep1) = { vpc_endpoint_id = aws_vpc_endpoint.custom.id }
  }
  privatelink_byoe_regions = { (local.ep1) = var.aws_region }
}

# Step 2: User-managed AWS VPC Endpoint with custom configuration
resource "aws_vpc_endpoint" "custom" {
  vpc_id             = var.vpc_id
  service_name       = module.atlas_aws.privatelink_service_info[local.ep1].endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "atlas-privatelink-custom"
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_aws.privatelink[local.ep1]
}

output "vpc_endpoint_id" {
  description = "VPC endpoint ID of the custom endpoint"
  value       = aws_vpc_endpoint.custom.id
}
