locals {
  atlas_service = "east"
  cross_region  = "cross_west"
}

module "atlas_aws" {
  source = "../../"

  project_id = var.project_id

  privatelink_byo_endpoint = {
    (local.atlas_service) = {
      region                   = var.atlas_service_region
      supported_remote_regions = [var.aws_region]
    }
  }

  privatelink_byo_service = {
    (local.cross_region) = {
      vpc_endpoint_id    = aws_vpc_endpoint.remote.id
      region             = var.aws_region
      service_region_key = local.atlas_service
    }
  }
}

resource "aws_vpc_endpoint" "remote" {
  vpc_id             = var.vpc_id
  service_name       = module.atlas_aws.privatelink_service_info[local.atlas_service].atlas_endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  service_region     = var.atlas_service_region
  region             = var.aws_region

  tags = {
    Name = "atlas-privatelink-cross-region"
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_aws.privatelink[local.cross_region]
}

output "vpc_endpoint_id" {
  description = "VPC endpoint ID of the cross-region endpoint"
  value       = aws_vpc_endpoint.remote.id
}
