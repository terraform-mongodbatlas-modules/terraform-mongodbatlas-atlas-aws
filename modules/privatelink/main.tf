
locals {
  aws_region                   = replace(lower(var.atlas_region), "_", "-")
  create_aws_vpc_endpoint      = var.existing_vpc_endpoint_id == ""
  vpc_endpoint_id              = local.create_aws_vpc_endpoint ? aws_vpc_endpoint.aws_endpoint[0].id : data.aws_vpc_endpoint.this[0].id
  vpc_id                       = local.create_aws_vpc_endpoint ? aws_vpc_endpoint.aws_endpoint[0].vpc_id : data.aws_vpc_endpoint.this[0].vpc_id
  vpc_cidr_block               = data.aws_vpc.this.cidr_block
  effective_security_group_ids = var.create_security_group ? [aws_security_group.mongodb_privatelink[0].id] : var.aws_private_endpoint.security_group_ids
}

resource "mongodbatlas_privatelink_endpoint" "mongodb_endpoint" {
  project_id    = var.project_id
  provider_name = "AWS"
  region        = local.aws_region
}

resource "aws_vpc_endpoint" "aws_endpoint" {
  count = local.create_aws_vpc_endpoint ? 1 : 0
  lifecycle {
    precondition {
      condition     = length(var.aws_private_endpoint.subnet_ids) > 0 && (var.create_security_group || length(var.aws_private_endpoint.security_group_ids) > 0)
      error_message = "subnet_ids must be provided, and either create_security_group=true or security_group_ids must be provided"
    }
  }

  vpc_id             = var.aws_private_endpoint.vpc_id
  service_name       = mongodbatlas_privatelink_endpoint.mongodb_endpoint.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.aws_private_endpoint.subnet_ids
  security_group_ids = local.effective_security_group_ids
  tags               = var.aws_tags
}

data "aws_vpc_endpoint" "this" {
  count        = local.create_aws_vpc_endpoint ? 0 : 1
  id           = var.existing_vpc_endpoint_id
  service_name = mongodbatlas_privatelink_endpoint.mongodb_endpoint.endpoint_service_name // ensure the vpc endpoint use the same service name as the atlas private endpoint
}

resource "mongodbatlas_privatelink_endpoint_service" "private_endpoint" {
  project_id          = mongodbatlas_privatelink_endpoint.mongodb_endpoint.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.mongodb_endpoint.private_link_id
  endpoint_service_id = local.vpc_endpoint_id
  provider_name       = "AWS"
}

data "aws_vpc" "this" {
  id = local.vpc_id
}

resource "aws_security_group" "mongodb_privatelink" {
  count       = var.create_security_group ? 1 : 0
  name_prefix = var.security_group_name_prefix
  description = "Security group for MongoDB Atlas private endpoint"
  vpc_id      = var.aws_private_endpoint.vpc_id
  tags        = var.aws_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mongodb_ingress_27017" {
  count             = var.create_security_group ? 1 : 0
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = coalesce(var.security_group_inbound_cidr_blocks, [local.vpc_cidr_block])
  security_group_id = aws_security_group.mongodb_privatelink[0].id
  description       = "MongoDB traffic"
}

resource "mongodbatlas_project_ip_access_list" "access_list_vpc_cidr_block" {
  count = var.add_vpc_cidr_block_project_access ? 1 : 0

  project_id = var.project_id
  cidr_block = local.vpc_cidr_block
  comment    = substr("Access to Atlas from the Private Endpoint in ${local.aws_region} for vpc ${local.vpc_id}", 0, 80) # MAX 80 chars

}
