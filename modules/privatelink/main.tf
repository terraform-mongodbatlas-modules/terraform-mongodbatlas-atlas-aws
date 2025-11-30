locals {
  aws_region                   = coalesce(var.aws_region, data.aws_region.current.name)
  vpc_id_from_subnet           = var.create_vpc_endpoint ? data.aws_subnet.selected[0].vpc_id : null
  vpc_endpoint_id              = var.create_vpc_endpoint ? aws_vpc_endpoint.aws_endpoint[0].id : data.aws_vpc_endpoint.this[0].id
  vpc_id                       = var.create_vpc_endpoint ? local.vpc_id_from_subnet : data.aws_vpc_endpoint.this[0].vpc_id
  vpc_cidr_block               = data.aws_vpc.this.cidr_block
  effective_security_group_ids = var.create_security_group ? [aws_security_group.mongodb_privatelink[0].id] : var.security_group_ids

  # Security group rule logic: null = VPC CIDR, [] = no CIDR rule
  create_cidr_rule       = var.create_security_group && (var.security_group_inbound_cidr_blocks == null || length(var.security_group_inbound_cidr_blocks) > 0)
  effective_cidr_blocks  = var.security_group_inbound_cidr_blocks == null ? [local.vpc_cidr_block] : var.security_group_inbound_cidr_blocks
  create_source_sg_rules = var.create_security_group && length(var.security_group_inbound_source_sgs) > 0
}

data "aws_region" "current" {}

data "aws_subnet" "selected" {
  count = var.create_vpc_endpoint ? 1 : 0
  id    = tolist(coalesce(var.subnet_ids, []))[0]
}

resource "mongodbatlas_privatelink_endpoint" "mongodb_endpoint" {
  project_id    = var.project_id
  provider_name = "AWS"
  region        = local.aws_region
}

resource "aws_vpc_endpoint" "aws_endpoint" {
  count = var.create_vpc_endpoint ? 1 : 0

  vpc_id             = local.vpc_id
  service_name       = mongodbatlas_privatelink_endpoint.mongodb_endpoint.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = coalesce(var.subnet_ids, [])
  security_group_ids = local.effective_security_group_ids
  tags               = var.aws_tags
}

data "aws_vpc_endpoint" "this" {
  count        = var.create_vpc_endpoint ? 0 : 1
  id           = var.existing_vpc_endpoint_id
  service_name = mongodbatlas_privatelink_endpoint.mongodb_endpoint.endpoint_service_name
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
  vpc_id      = local.vpc_id
  tags        = var.aws_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mongodb_ingress_cidr" {
  count             = local.create_cidr_rule ? 1 : 0
  type              = "ingress"
  from_port         = 27015
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = local.effective_cidr_blocks
  security_group_id = aws_security_group.mongodb_privatelink[0].id
  description       = "MongoDB Atlas traffic (ports 27015-27017)"
}

resource "aws_security_group_rule" "mongodb_ingress_sg" {
  for_each                 = local.create_source_sg_rules ? var.security_group_inbound_source_sgs : []
  type                     = "ingress"
  from_port                = 27015
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.mongodb_privatelink[0].id
  description              = "MongoDB Atlas traffic (ports 27015-27017)"
}
