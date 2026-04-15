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
  description = "IAM role name for attaching S3 policy"
}

variable "skip_iam_policy_attachments" {
  type        = bool
  default     = false
  description = "Skip creating S3 IAM role policy and time_sleep. Must be plan-time known."
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
    versioning_enabled      = optional(bool, false)
    server_side_encryption  = optional(string, "aws:kms")
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
    expiration_days         = optional(number, 365)
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
    - Versioning disabled (Atlas writes timestamp-based keys, no overwrite risk)
    - SSE with aws:kms for encryption at rest
    - All public access blocked

    **Lifecycle:**
    - `expiration_days` - Auto-delete objects after N days (default 365, 0 to disable)
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
    condition     = try(var.create_s3_bucket.name, null) == null || !strcontains(var.create_s3_bucket.name, ".")
    error_message = "name must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = try(var.create_s3_bucket.name_prefix, null) == null || !strcontains(var.create_s3_bucket.name_prefix, ".")
    error_message = "name_prefix must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = var.create_s3_bucket.expiration_days >= 0 && floor(var.create_s3_bucket.expiration_days) == var.create_s3_bucket.expiration_days
    error_message = "expiration_days must be a non-negative whole number. Use 0 to disable the lifecycle rule."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = null
  nullable    = true
  description = "Timeout overrides. null = provider defaults."
}
