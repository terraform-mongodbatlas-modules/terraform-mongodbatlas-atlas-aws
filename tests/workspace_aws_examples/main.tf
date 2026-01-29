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
  })
  default = {}
}

module "project" {
  for_each = toset(local.missing_project_ids)
  source   = "../project_generator"
  org_id   = var.org_id
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
}

# Example module calls are generated in modules.generated.tf
