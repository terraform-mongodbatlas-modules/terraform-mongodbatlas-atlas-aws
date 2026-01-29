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
    privatelink                 = optional(string)
    privatelink_byoe            = optional(string)
    privatelink_multi_region    = optional(string)
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

locals {
  missing_project_ids = [for k, v in var.project_ids : k if v == null]
  project_ids         = { for k, v in var.project_ids : k => v != null ? v : module.project[k].project_id }

  # tflint-ignore: terraform_unused_declarations
  project_id_encryption = local.project_ids.encryption
  # tflint-ignore: terraform_unused_declarations
  project_id_encryption_private_endpoint = local.project_ids.encryption_private_endpoint
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
}

# Example module calls are generated in modules.generated.tf
