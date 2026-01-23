locals {
  atlas_region = upper(replace(var.region, "-", "_"))
}

resource "mongodbatlas_encryption_at_rest_private_endpoint" "this" {
  project_id     = var.project_id
  cloud_provider = "AWS"
  region_name    = local.atlas_region
}
