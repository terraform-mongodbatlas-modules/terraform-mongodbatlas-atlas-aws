terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.9"
}

provider "mongodbatlas" {}
provider "aws" {}

variable "org_id" {
  type    = string
  default = ""
}

variable "project_ids" {
  type = object({
    encryption                  = optional(string)
    encryption_private_endpoint = optional(string)
    backup_export               = optional(string)
    log_integration             = optional(string)
    privatelink                 = optional(string)
    privatelink_byoe            = optional(string)
    privatelink_multi_region    = optional(string)
    byo_role                    = optional(string)
  })
  default = {}
}

module "project" {
  for_each = toset(local.missing_project_ids)
  source   = "../project_generator"
  org_id   = var.org_id
}

# VPC for privatelink example (us-east-1)
module "vpc_privatelink" {
  source      = "../vpc_generator"
  vpc_cidr    = "10.10.0.0/16"
  subnet_cidr = "10.10.1.0/24"
  name_prefix = "atlas-pl-"
}

# VPC for privatelink_byoe example (us-east-1)
module "vpc_privatelink_byoe" {
  source      = "../vpc_generator"
  vpc_cidr    = "10.11.0.0/16"
  subnet_cidr = "10.11.1.0/24"
  name_prefix = "atlas-pl-byoe-"
}

# VPC for privatelink_multi_region us-east-1
module "vpc_multi_region_us_east_1" {
  source      = "../vpc_generator"
  region      = "us-east-1"
  vpc_cidr    = "10.12.0.0/16"
  subnet_cidr = "10.12.1.0/24"
  name_prefix = "atlas-pl-multi-use1-"
}

# VPC for privatelink_multi_region us-west-2
module "vpc_multi_region_us_west_2" {
  source      = "../vpc_generator"
  region      = "us-west-2"
  vpc_cidr    = "10.13.0.0/16"
  subnet_cidr = "10.13.1.0/24"
  name_prefix = "atlas-pl-multi-usw2-"
}

module "byo_cpa" {
  source     = "../../modules/cloud_provider_access"
  project_id = local.project_id_byo_role
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "byo_kms" {
  statement {
    sid       = "AllowRootFullAccess"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid    = "AllowCPARoleKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [module.byo_cpa.iam_role_arn]
    }
  }
}

resource "aws_kms_key" "byo" {
  description             = "BYO KMS key for byo_role example"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.byo_kms.json
}

resource "aws_s3_bucket" "byo" {
  bucket_prefix = "atlas-byo-role-"
  force_destroy = true
}

data "aws_iam_policy_document" "byo_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:PutObject"]
    resources = [aws_s3_bucket.byo.arn, "${aws_s3_bucket.byo.arn}/*"]
  }
}

resource "aws_iam_role_policy" "byo_s3" {
  name   = "atlas-byo-s3-access"
  role   = module.byo_cpa.iam_role_name
  policy = data.aws_iam_policy_document.byo_s3.json
}

locals {
  missing_project_ids = [for k, v in var.project_ids : k if v == null]
  project_ids         = { for k, v in var.project_ids : k => v != null ? v : module.project[k].project_id }

  # tflint-ignore: terraform_unused_declarations
  project_id_encryption = local.project_ids.encryption
  # tflint-ignore: terraform_unused_declarations
  project_id_encryption_private_endpoint = local.project_ids.encryption_private_endpoint
  # tflint-ignore: terraform_unused_declarations
  project_id_backup_export = local.project_ids.backup_export
  # tflint-ignore: terraform_unused_declarations
  project_id_log_integration = local.project_ids.log_integration
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink = local.project_ids.privatelink
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_byoe = local.project_ids.privatelink_byoe
  # tflint-ignore: terraform_unused_declarations
  project_id_privatelink_multi_region = local.project_ids.privatelink_multi_region

  # Network resources for privatelink examples
  # tflint-ignore: terraform_unused_declarations
  vpc_id_privatelink = module.vpc_privatelink.vpc_id
  # tflint-ignore: terraform_unused_declarations
  subnet_ids_privatelink = module.vpc_privatelink.subnet_ids

  # tflint-ignore: terraform_unused_declarations
  vpc_id_privatelink_byoe = module.vpc_privatelink_byoe.vpc_id
  # tflint-ignore: terraform_unused_declarations
  subnet_ids_privatelink_byoe = module.vpc_privatelink_byoe.subnet_ids
  # tflint-ignore: terraform_unused_declarations
  security_group_ids_byoe = [module.vpc_privatelink_byoe.security_group_id]

  # tflint-ignore: terraform_unused_declarations
  subnet_ids_us_east_1 = module.vpc_multi_region_us_east_1.subnet_ids
  # tflint-ignore: terraform_unused_declarations
  subnet_ids_us_west_2 = module.vpc_multi_region_us_west_2.subnet_ids

  # tflint-ignore: terraform_unused_declarations
  project_id_byo_role = local.project_ids.byo_role
  # tflint-ignore: terraform_unused_declarations
  byo_role_id = module.byo_cpa.role_id
  # tflint-ignore: terraform_unused_declarations
  byo_iam_role_arn = module.byo_cpa.iam_role_arn
  # tflint-ignore: terraform_unused_declarations
  byo_kms_key_arn = aws_kms_key.byo.arn
  # tflint-ignore: terraform_unused_declarations
  byo_s3_bucket_name = aws_s3_bucket.byo.bucket
}

# Example module calls are generated in modules.generated.tf
