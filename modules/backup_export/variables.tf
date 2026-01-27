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
  description = "Module-managed S3 bucket configuration"

  validation {
    condition     = !(try(var.create_s3_bucket.name, null) != null && try(var.create_s3_bucket.name_prefix, null) != null)
    error_message = "Cannot use both name and name_prefix."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
