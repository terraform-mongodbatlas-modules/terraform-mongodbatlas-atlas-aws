locals {
  # Input validation
  _validate_kms_key        = var.create_kms_key || var.aws_kms_key_arn != null ? true : tobool("aws_kms_key_arn is required when create_kms_key is false")
  _validate_iam_role       = var.create_kms_iam_role || var.existing_aws_iam_role_name != null ? true : tobool("existing_aws_iam_role_name is required when create_kms_iam_role is false")
  _validate_security_group = !var.private_networking.create_aws_kms_vpc_endpoint || var.private_networking.create_security_group || length(var.private_networking.security_group_ids) > 0 ? true : tobool("Either create_security_group must be true or security_group_ids must be provided when create_kms_vpc_endpoint is true")

  # Infer whether to authorize based on atlas_role_id presence
  authorize_iam_role = var.atlas_role_id == null

  role_name     = var.create_kms_iam_role ? aws_iam_role.kms[0].name : var.existing_aws_iam_role_name
  iam_role_arn  = var.create_kms_iam_role ? aws_iam_role.kms[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.existing_aws_iam_role_name}"
  kms_key_arn   = var.create_kms_key ? aws_kms_key.this[0].arn : var.aws_kms_key_arn
  atlas_role_id = local.authorize_iam_role ? mongodbatlas_cloud_provider_access_authorization.kms[0].role_id : var.atlas_role_id
  vpc_id        = var.private_networking.create_aws_kms_vpc_endpoint ? data.aws_subnet.selected[0].vpc_id : null
  aws_region    = coalesce(var.aws_region, data.aws_region.current.name)

  # Security group configuration - use custom CIDRs if provided, otherwise default to VPC CIDR
  security_group_cidr_blocks = var.private_networking.create_security_group ? (
    var.private_networking.security_group_inbound_cidr_blocks != null
    ? var.private_networking.security_group_inbound_cidr_blocks
    : [data.aws_vpc.selected[0].cidr_block]
  ) : []
  
  # Combine created and provided security group IDs for VPC endpoint
  vpc_endpoint_security_group_ids = concat(
    var.private_networking.create_security_group ? [aws_security_group.kms_endpoint[0].id] : [],
    tolist(var.private_networking.security_group_ids)
  )
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Get VPC info from subnet when creating KMS VPC endpoint
data "aws_subnet" "selected" {
  count = var.private_networking.create_aws_kms_vpc_endpoint ? 1 : 0
  id    = tolist(var.private_networking.vpc_endpoint_subnet_ids)[0]
}

data "aws_vpc" "selected" {
  count = var.private_networking.create_aws_kms_vpc_endpoint ? 1 : 0
  id    = data.aws_subnet.selected[0].vpc_id
}

#------------------------------------------------------------------------------
# KMS Key Resources (created when create_kms_key = true)
#------------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  count = var.create_kms_key ? 1 : 0

  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true

  tags = var.aws_tags
}

resource "aws_kms_alias" "this" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.this[0].key_id
}

#------------------------------------------------------------------------------
# Cloud Provider Access (created when authorize_iam_role = true)
#------------------------------------------------------------------------------

resource "mongodbatlas_cloud_provider_access_setup" "kms" {
  count = local.authorize_iam_role ? 1 : 0

  project_id    = var.project_id
  provider_name = "AWS"
}

resource "aws_iam_role" "kms" {
  count = var.create_kms_iam_role ? 1 : 0

  name = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = mongodbatlas_cloud_provider_access_setup.kms[0].aws_config[0].atlas_aws_account_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = mongodbatlas_cloud_provider_access_setup.kms[0].aws_config[0].atlas_assumed_role_external_id
          }
        }
      }
    ]
  })

  tags = var.aws_tags
}

resource "aws_iam_role_policy" "kms" {
  name = var.aws_iam_role_policy_name
  role = var.create_kms_iam_role ? aws_iam_role.kms[0].id : local.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey"
        ]
        Resource = [local.kms_key_arn]
      }
    ]
  })
}

resource "mongodbatlas_cloud_provider_access_authorization" "kms" {
  count = local.authorize_iam_role ? 1 : 0

  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.kms[0].role_id

  aws {
    iam_assumed_role_arn = local.iam_role_arn
  }

  depends_on = [
    aws_iam_role.kms,
    aws_iam_role_policy.kms
  ]
}


#------------------------------------------------------------------------------
# KMS VPC Endpoint (for require_private_networking = true)
#------------------------------------------------------------------------------

resource "aws_security_group" "kms_endpoint" {
  count = var.private_networking.create_security_group ? 1 : 0

  name_prefix = var.private_networking.security_group_name_prefix
  description = "Security group for KMS VPC endpoint"
  vpc_id      = local.vpc_id

  tags = var.aws_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "kms_ingress_https" {
  count = var.private_networking.create_security_group ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.security_group_cidr_blocks
  security_group_id = aws_security_group.kms_endpoint[0].id
  description       = "HTTPS from VPC for KMS API calls"
}

resource "aws_vpc_endpoint" "kms" {
  count = var.private_networking.create_aws_kms_vpc_endpoint ? 1 : 0

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${local.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_networking.vpc_endpoint_subnet_ids
  security_group_ids  = local.vpc_endpoint_security_group_ids
  private_dns_enabled = true

  tags = var.aws_tags
}

#------------------------------------------------------------------------------
# MongoDB Atlas Encryption at Rest
#------------------------------------------------------------------------------

resource "mongodbatlas_encryption_at_rest" "this" {
  project_id = var.project_id

  aws_kms_config {
    enabled                    = true
    customer_master_key_id     = local.kms_key_arn
    region                     = var.atlas_region
    role_id                    = local.atlas_role_id
    require_private_networking = var.private_networking.require_private_networking
  }

  enabled_for_search_nodes = var.enabled_for_search_nodes

  lifecycle {
    postcondition {
      condition     = self.aws_kms_config[0].valid
      error_message = "AWS KMS config is not valid"
    }
  }

  depends_on = [
    mongodbatlas_cloud_provider_access_authorization.kms,
    aws_iam_role_policy.kms
  ]
}

resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  count = var.private_networking.create_atlas_private_endpoint ? 1 : 0

  project_id     = mongodbatlas_encryption_at_rest.this.project_id
  cloud_provider = "AWS"
  region_name    = var.atlas_region

  depends_on = [aws_vpc_endpoint.kms]
}
