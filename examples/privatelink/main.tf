data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

module "atlas_aws" {
  source     = "../../"
  project_id = var.project_id

  privatelink_endpoints = [
    {
      region     = var.aws_region
      subnet_ids = data.aws_subnets.private.ids
    }
  ]
}

output "privatelink" {
  value = module.atlas_aws.privatelink
}
