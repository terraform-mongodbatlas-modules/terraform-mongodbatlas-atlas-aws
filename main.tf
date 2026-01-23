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
