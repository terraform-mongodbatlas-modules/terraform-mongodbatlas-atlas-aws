locals {
  # Normalize to AWS format (handles us-east-1 or US_EAST_1 input)
  region              = lower(replace(var.region, "_", "-"))
  create_vpc_endpoint = var.vpc_endpoint.create
  vpc_id_from_subnet  = local.create_vpc_endpoint ? data.aws_subnet.selected[0].vpc_id : null
  vpc_id              = local.create_vpc_endpoint ? local.vpc_id_from_subnet : try(data.aws_vpc_endpoint.byo[0].vpc_id, null)

  sg_ids_provided  = var.security_group.ids != null
  should_create_sg = !local.sg_ids_provided && var.security_group.create && local.create_vpc_endpoint
  effective_security_group_ids = coalesce(
    var.security_group.ids,
    local.should_create_sg ? [aws_security_group.this[0].id] : []
  )

  create_cidr_rule = local.should_create_sg && (var.security_group.inbound_cidr_blocks == null || length(var.security_group.inbound_cidr_blocks) > 0)
  # Guard with should_create_sg to avoid accessing data.aws_vpc.this when it doesn't exist (BYOE mode)
  effective_cidr_blocks = local.should_create_sg ? (
    var.security_group.inbound_cidr_blocks == null ? [data.aws_vpc.this[0].cidr_block] : var.security_group.inbound_cidr_blocks
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
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = var.project_id
  private_link_id     = var.private_link_id
  provider_name       = "AWS"
  endpoint_service_id = local.create_vpc_endpoint ? aws_vpc_endpoint.this[0].id : var.byo_vpc_endpoint_id
}

data "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = var.project_id
  private_link_id     = var.private_link_id
  endpoint_service_id = mongodbatlas_privatelink_endpoint_service.this.endpoint_service_id
  provider_name       = "AWS"

  depends_on = [mongodbatlas_privatelink_endpoint_service.this]
}
