variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_role_id" {
  type        = string
  description = "Atlas cloud provider access role ID (passed to iam_role_id attribute)"
}

variable "iam_role_name" {
  type        = string
  description = "IAM role name for attaching S3 policy"
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "User-provided S3 bucket name"
}

variable "create_s3_bucket" {
  type = object({
    enabled                 = bool
    region                  = optional(string)
    name                    = optional(string)
    name_prefix             = optional(string)
    force_destroy           = optional(bool, false)
    versioning_enabled      = optional(bool, true)
    server_side_encryption  = optional(string, "aws:kms")
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {
    enabled = false
  }
  nullable    = false
  description = <<-EOT
    Module-managed S3 bucket configuration.

    **Region:**
    - `region` - Region (us-east-1 or US_EAST_1), defaults to provider's region

    **Bucket Naming:**
    - `name` - Exact bucket name (conflicts with name_prefix)
    - `name_prefix` - Prefix with Terraform-generated suffix (max 37 chars)
    - Default: `atlas-backup-{project_id_suffix}-` when neither specified

    **Security Defaults:**
    - Versioning enabled for backup recovery
    - SSE with aws:kms for encryption at rest
    - All public access blocked
  EOT

  validation {
    condition     = !(try(var.create_s3_bucket.name, null) != null && try(var.create_s3_bucket.name_prefix, null) != null)
    error_message = "Cannot use both name and name_prefix."
  }

  validation {
    condition     = try(length(var.create_s3_bucket.name_prefix), 0) <= 37
    error_message = "name_prefix must be 37 characters or less. S3 bucket names are limited to 63 characters and Terraform adds a 26-character random suffix."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
