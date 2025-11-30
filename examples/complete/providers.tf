terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.1"
    }
  }
}

# Configure AWS Provider
provider "aws" {}

# Configure MongoDB Atlas Provider
provider "mongodbatlas" {}
