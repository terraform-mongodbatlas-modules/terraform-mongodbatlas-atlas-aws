locals {
  aws_region   = lower(replace(var.region, "_", "-"))
  atlas_region = upper(replace(local.aws_region, "-", "_"))
}

resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AWS"
  region_name    = local.atlas_region
}

data "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AWS"
  id             = mongodbatlas_encryption_at_rest_private_endpoint.this.id
}
