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
  default     = null
  description = "IAM role name for attaching S3 and KMS policies"
}

variable "skip_iam_policy_attachments" {
  type        = bool
  default     = false
  description = "Skip creating S3/KMS IAM role policies and time_sleep. Must be plan-time known."
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
    expiration_days         = optional(number, 90)
  })
  default = {
    enabled = false
  }
  nullable    = false
  description = <<-EOT
    Module-managed S3 bucket configuration.

    **Bucket Naming:**
    - `name` - Exact bucket name (conflicts with name_prefix)
    - `name_prefix` - Prefix with Terraform-generated suffix (max 37 chars)
    - Default: `atlas-logs-{project_id_suffix}-` when neither specified

    **Lifecycle:**
    - `expiration_days` - Auto-delete objects after N days (default 90, 0 to disable)
  EOT

  validation {
    condition     = !(try(var.create_s3_bucket.name, null) != null && try(var.create_s3_bucket.name_prefix, null) != null)
    error_message = "Cannot use both name and name_prefix."
  }

  validation {
    condition     = try(length(var.create_s3_bucket.name_prefix), 0) <= 37
    error_message = "name_prefix must be 37 characters or less. S3 bucket names are limited to 63 characters and Terraform adds a 26-character random suffix."
  }

  validation {
    condition     = var.create_s3_bucket.expiration_days >= 0 && floor(var.create_s3_bucket.expiration_days) == var.create_s3_bucket.expiration_days
    error_message = "expiration_days must be a non-negative whole number. Use 0 to disable the lifecycle rule."
  }
}

variable "integrations" {
  type = list(object({
    log_types   = list(string)
    prefix_path = string
    bucket_name = optional(string)
  }))
  description = "List of log integration configurations. Each entry creates one mongodbatlas_log_integration resource. `prefix_path` (required) sets the S3 object key prefix for log delivery. `bucket_name` (optional) overrides the default bucket."
}

variable "kms_key" {
  type        = string
  default     = null
  description = "Atlas-side KMS key ARN for encrypting log objects before writing to S3"
}

variable "kms_key_skip_iam_policy" {
  type        = bool
  default     = false
  description = "Skip attaching kms:GenerateDataKey + kms:Decrypt + kms:DescribeKey to the CPA role. Set to true when the KMS key policy already grants access."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
