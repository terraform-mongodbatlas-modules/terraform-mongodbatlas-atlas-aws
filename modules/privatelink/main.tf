locals {
  region              = lower(replace(var.region, "_", "-"))
  create_vpc_endpoint = var.vpc_endpoint.create

  # Prefer vpc_id/vpc_cidr_block from the root module to avoid re-reading inside
  # the submodule. The module call carries `depends_on`, so Terraform defers ALL
  # data source reads here when any dependency has pending changes, producing
  # "known after apply" that cascades into ForceNew on SG and VPC endpoint.
  # The data sources below are kept for standalone submodule users who don't
  # pass these variables. See: https://github.com/hashicorp/terraform/issues/26383
  vpc_id = var.vpc_id != null ? var.vpc_id : (
    local.create_vpc_endpoint ? data.aws_subnet.selected[0].vpc_id : try(data.aws_vpc_endpoint.byo[0].vpc_id, null)
  )

  sg_ids_provided  = var.security_group.ids != null
  should_create_sg = !local.sg_ids_provided && var.security_group.create && local.create_vpc_endpoint
  effective_security_group_ids = coalesce(
    var.security_group.ids,
    local.should_create_sg ? [aws_security_group.this[0].id] : []
  )

  create_cidr_rule = local.should_create_sg && (var.security_group.inbound_cidr_blocks == null || length(var.security_group.inbound_cidr_blocks) > 0)
  effective_cidr_blocks = local.should_create_sg ? (
    var.security_group.inbound_cidr_blocks == null
    ? [var.vpc_cidr_block != null ? var.vpc_cidr_block : data.aws_vpc.this[0].cidr_block]
    : var.security_group.inbound_cidr_blocks
  ) : []
  create_sg_rules = local.should_create_sg && length(var.security_group.inbound_source_sgs) > 0
}

data "aws_subnet" "selected" {
  count  = local.create_vpc_endpoint ? 1 : 0
  id     = var.vpc_endpoint.subnet_ids[0]
  region = local.region
}

data "aws_vpc" "this" {
  count  = local.should_create_sg ? 1 : 0
  id     = local.vpc_id
  region = local.region
}

data "aws_vpc_endpoint" "byo" {
  count  = local.create_vpc_endpoint ? 0 : 1
  id     = var.byo_vpc_endpoint_id
  region = local.region
}

resource "aws_security_group" "this" {
  count       = local.should_create_sg ? 1 : 0
  name_prefix = var.security_group.name_prefix
  description = "MongoDB Atlas PrivateLink"
  vpc_id      = local.vpc_id
  tags        = var.tags
  region      = local.region

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_cidr" {
  count             = local.create_cidr_rule ? 1 : 0
  region            = local.region
  type              = "ingress"
  from_port         = var.security_group.from_port
  to_port           = var.security_group.to_port
  protocol          = "tcp"
  cidr_blocks       = local.effective_cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = "MongoDB Atlas PrivateLink"
}

resource "aws_security_group_rule" "ingress_sg" {
  for_each                 = local.create_sg_rules ? var.security_group.inbound_source_sgs : toset([])
  region                   = local.region
  type                     = "ingress"
  from_port                = var.security_group.from_port
  to_port                  = var.security_group.to_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.this[0].id
  description              = "MongoDB Atlas PrivateLink from source SG"
}

resource "aws_vpc_endpoint" "this" {
  count              = local.create_vpc_endpoint ? 1 : 0
  vpc_id             = local.vpc_id
  service_name       = var.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.vpc_endpoint.subnet_ids
  security_group_ids = local.effective_security_group_ids
  tags               = var.tags
  region             = local.region
  service_region     = var.service_region != null ? lower(replace(var.service_region, "_", "-")) : null

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = var.project_id
  private_link_id     = var.private_link_id
  provider_name       = "AWS"
  endpoint_service_id = local.create_vpc_endpoint ? aws_vpc_endpoint.this[0].id : var.byo_vpc_endpoint_id

  dynamic "timeouts" {
    for_each = var.timeouts[*]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

data "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = var.project_id
  private_link_id     = var.private_link_id
  endpoint_service_id = mongodbatlas_privatelink_endpoint_service.this.endpoint_service_id
  provider_name       = "AWS"

  depends_on = [mongodbatlas_privatelink_endpoint_service.this]
}
