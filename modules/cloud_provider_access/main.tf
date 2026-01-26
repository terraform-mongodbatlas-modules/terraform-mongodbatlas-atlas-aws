resource "mongodbatlas_cloud_provider_access_setup" "this" {
  project_id    = var.project_id
  provider_name = "AWS"
}

locals {
  project_id_suffix = substr(var.project_id, max(0, length(var.project_id) - 8), 8)
  default_prefix    = "mongodb-atlas-${local.project_id_suffix}-${var.purpose}"
  iam_role_name     = coalesce(var.iam_role_name, local.default_prefix)
  name_prefix       = var.iam_role_name == null ? local.default_prefix : null
}

data "aws_iam_policy_document" "atlas_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [mongodbatlas_cloud_provider_access_setup.this.aws_config[0].atlas_aws_account_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [mongodbatlas_cloud_provider_access_setup.this.aws_config[0].atlas_assumed_role_external_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.iam_role_name
  name_prefix          = local.name_prefix
  path                 = var.iam_role_path
  assume_role_policy   = data.aws_iam_policy_document.atlas_assume_role.json
  permissions_boundary = var.iam_role_permissions_boundary
  tags                 = var.tags
}

resource "mongodbatlas_cloud_provider_access_authorization" "this" {
  project_id = var.project_id
  role_id    = mongodbatlas_cloud_provider_access_setup.this.role_id

  aws {
    iam_assumed_role_arn = aws_iam_role.this.arn
  }
}
