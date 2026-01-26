locals {
  vpc_id_from_subnet = var.create_vpc_endpoint && length(var.subnet_ids) > 0 ? data.aws_subnet.selected[0].vpc_id : null
  vpc_id             = var.create_vpc_endpoint ? local.vpc_id_from_subnet : try(data.aws_vpc_endpoint.existing[0].vpc_id, null)

  should_create_sg = var.create_security_group && var.security_group_ids == null && var.create_vpc_endpoint
  effective_security_group_ids = coalesce(
    var.security_group_ids,
    local.should_create_sg ? [aws_security_group.this[0].id] : []
  )

  create_cidr_rule      = local.should_create_sg && (var.security_group_inbound_cidr_blocks == null || length(var.security_group_inbound_cidr_blocks) > 0)
  effective_cidr_blocks = var.security_group_inbound_cidr_blocks == null ? [data.aws_vpc.this[0].cidr_block] : var.security_group_inbound_cidr_blocks
  create_sg_rules       = local.should_create_sg && length(var.security_group_inbound_source_sgs) > 0
}

data "aws_subnet" "selected" {
  count  = var.create_vpc_endpoint && length(var.subnet_ids) > 0 ? 1 : 0
  id     = var.subnet_ids[0]
  region = var.region
}

data "aws_vpc" "this" {
  count  = local.should_create_sg ? 1 : 0
  id     = local.vpc_id
  region = var.region
}

data "aws_vpc_endpoint" "existing" {
  count  = var.create_vpc_endpoint ? 0 : 1
  id     = var.existing_vpc_endpoint_id
  region = var.region
}

resource "aws_security_group" "this" {
  count       = local.should_create_sg ? 1 : 0
  name_prefix = var.security_group_name_prefix
  description = "MongoDB Atlas PrivateLink"
  vpc_id      = local.vpc_id
  tags        = var.tags
  region      = var.region

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_cidr" {
  count             = local.create_cidr_rule ? 1 : 0
  type              = "ingress"
  from_port         = var.security_group_from_port
  to_port           = var.security_group_to_port
  protocol          = "tcp"
  cidr_blocks       = local.effective_cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = "MongoDB Atlas PrivateLink"
}

resource "aws_security_group_rule" "ingress_sg" {
  for_each                 = local.create_sg_rules ? var.security_group_inbound_source_sgs : toset([])
  type                     = "ingress"
  from_port                = var.security_group_from_port
  to_port                  = var.security_group_to_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.this[0].id
  description              = "MongoDB Atlas PrivateLink from source SG"
}

resource "aws_vpc_endpoint" "this" {
  count              = var.create_vpc_endpoint ? 1 : 0
  vpc_id             = local.vpc_id
  service_name       = var.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = local.effective_security_group_ids
  tags               = var.tags
  region             = var.region

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) > 0
      error_message = "subnet_ids required when create_vpc_endpoint = true"
    }
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = var.project_id
  private_link_id     = var.private_link_id
  provider_name       = "AWS"
  endpoint_service_id = var.create_vpc_endpoint ? aws_vpc_endpoint.this[0].id : var.existing_vpc_endpoint_id

  lifecycle {
    precondition {
      condition     = var.create_vpc_endpoint || var.existing_vpc_endpoint_id != null
      error_message = "BYOE mode requires existing_vpc_endpoint_id"
    }
  }
}
