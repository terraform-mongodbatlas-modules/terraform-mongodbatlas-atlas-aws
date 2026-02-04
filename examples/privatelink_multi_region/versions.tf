terraform {
  required_version = ">= 1.9"

  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  provider_meta "mongodbatlas" {
    module_name    = "atlas-aws"
    module_version = "local"
  }
}

provider "mongodbatlas" {}
provider "aws" {
  region = var.aws_region
}
