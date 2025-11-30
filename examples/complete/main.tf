# MongoDB Atlas Project
resource "mongodbatlas_project" "this" {
  name   = var.project_name
  org_id = var.org_id
}

# Atlas-AWS Integration Module
module "atlas_aws" {
  source = "../../"

  project_id   = mongodbatlas_project.this.id
  atlas_region = var.atlas_region

  aws_tags = {
    atlas_project = mongodbatlas_project.this.id
  }

  # Encryption at rest - create KMS key and dedicated IAM role
  encryption_at_rest = {
    enabled             = true
    create_kms_key      = true
    create_kms_iam_role = true
    kms_key_alias       = "${var.project_name}-atlas"
    aws_iam_role_name   = "${var.project_name}-atlas-kms-role"
  }

  # Push-based log export - create S3 bucket and dedicated IAM role
  push_based_log_export = {
    enabled           = true
    create_iam_role   = true
    create_s3_bucket  = true
    bucket_name       = "${var.project_name}-atlas-logs"
    aws_iam_role_name = "${var.project_name}-atlas-logs-role"
    prefix_path       = "mongodb-logs"
  }

  # Private endpoint with managed security group
  privatelink = {
    enabled               = true
    create_vpc_endpoint   = true
    subnet_ids            = toset(var.aws_subnet_ids)
    create_security_group = true
  }
}
