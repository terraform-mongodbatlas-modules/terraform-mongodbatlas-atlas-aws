
terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.1"
    }
  }
  required_version = ">= 1.8"
}
