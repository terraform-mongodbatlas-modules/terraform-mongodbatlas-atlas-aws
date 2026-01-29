data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  count = var.subnet_ids == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

locals {
  subnet_ids = var.subnet_ids != null ? var.subnet_ids : data.aws_subnets.private[0].ids
}

module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  privatelink_endpoints = [
    {
      region     = var.aws_region
      subnet_ids = local.subnet_ids
    }
  ]
}

output "privatelink" {
  value = module.atlas_aws.privatelink
}
