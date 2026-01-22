module "cloud_provider_access" {
  count  = local.create_cloud_provider_access ? 1 : 0
  source = "./modules/cloud_provider_access"

  project_id                    = var.project_id
  purpose                       = "shared"
  iam_role_name                 = var.cloud_provider_access.iam_role_name
  iam_role_path                 = var.cloud_provider_access.iam_role_path
  iam_role_permissions_boundary = var.cloud_provider_access.iam_role_permissions_boundary
  tags                          = var.aws_tags
}

resource "mongodbatlas_private_endpoint_regional_mode" "this" {
  count      = local.enable_regional_mode ? 1 : 0
  project_id = var.project_id
  enabled    = true
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  for_each      = local.privatelink_key_region
  project_id    = var.project_id
  provider_name = "AWS"
  region        = each.value
}
