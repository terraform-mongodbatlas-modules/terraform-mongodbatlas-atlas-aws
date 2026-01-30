variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "cloud_provider_access" {
  type = object({
    create = optional(bool, true)
    existing = optional(object({
      role_id      = string
      iam_role_arn = string
    }))
    iam_role_name                 = optional(string)
    iam_role_path                 = optional(string, "/")
    iam_role_permissions_boundary = optional(string)
  })
  default     = {}
  description = <<-EOT
    Cloud provider access configuration for Atlas-AWS integration.

    - `create = true` (default): Creates a shared IAM role and Atlas authorization
    - `create = false`: Use existing role via `existing.role_id` and `existing.iam_role_arn`
    - `iam_role_name`: Custom name for the IAM role (default: atlas-{project_id_suffix}-{purpose})
    - `iam_role_path`: IAM role path (default: /)
    - `iam_role_permissions_boundary`: ARN of permissions boundary policy
  EOT

  validation {
    condition     = var.cloud_provider_access.create || var.cloud_provider_access.existing != null
    error_message = "When cloud_provider_access.create = false, existing.role_id and existing.iam_role_arn are required."
  }
}

variable "encryption" {
  type = object({
    enabled     = optional(bool, false)
    kms_key_arn = optional(string)
    region      = optional(string)
    create_kms_key = optional(object({
      enabled                 = bool
      alias                   = optional(string, "alias/atlas-encryption")
      deletion_window_in_days = optional(number, 7)
      enable_key_rotation     = optional(bool, true)
      policy_override         = optional(string)
    }))
    private_endpoint_regions = optional(set(string), [])
    iam_role = optional(object({
      create               = optional(bool, false)
      name                 = optional(string)
      path                 = optional(string, "/")
      permissions_boundary = optional(string)
    }), { create = false })
  })
  default     = {}
  description = <<-EOT
    Encryption at rest configuration with AWS KMS.

    Provide EITHER:
    - `kms_key_arn` (user-provided KMS key)
    - `create_kms_key.enabled = true` (module-managed KMS key)

    **IAM Role Strategy:**
    - `iam_role.create = false` (default): Uses the shared IAM role from `cloud_provider_access`.
    - `iam_role.create = true`: Creates a dedicated IAM role for encryption.

    **Private Networking:**
    When `private_endpoint_regions` is non-empty, Atlas creates PrivateLink connections to AWS KMS. Traffic stays on AWS's private network. No user-side VPC endpoint required.
  EOT

  validation {
    condition     = !(var.encryption.kms_key_arn != null && try(var.encryption.create_kms_key.enabled, false))
    error_message = "Cannot use both kms_key_arn (user-provided) and create_kms_key.enabled = true (module-managed)."
  }

  validation {
    condition     = !var.encryption.enabled || (var.encryption.kms_key_arn != null || try(var.encryption.create_kms_key.enabled, false))
    error_message = "encryption.enabled = true requires kms_key_arn OR create_kms_key.enabled = true."
  }

  validation {
    condition     = length(var.encryption.private_endpoint_regions) == 0 || var.encryption.enabled
    error_message = "private_endpoint_regions requires encryption.enabled = true."
  }
}

variable "privatelink_endpoints" {
  type = list(object({
    region     = string
    subnet_ids = list(string)
    security_group = optional(object({
      ids                 = optional(list(string))
      create              = optional(bool, true)
      name_prefix         = optional(string, "atlas-privatelink-")
      inbound_cidr_blocks = optional(list(string)) # null = VPC CIDR, [] = no rule
      inbound_source_sgs  = optional(set(string), [])
      from_port           = optional(number, 1024)
      to_port             = optional(number, 65535)
    }), {})
    tags = optional(map(string), {})
  }))
  default     = []
  description = <<-EOT
    Multi-region PrivateLink endpoints. Region accepts us-east-1 or US_EAST_1 format. All regions must be UNIQUE.
    See [Port ranges used for private endpoints](https://www.mongodb.com/docs/atlas/security-private-endpoint/#port-ranges-used-for-private-endpoints) for port range details.
  EOT

  validation {
    condition     = length(var.privatelink_endpoints) == length(distinct([for ep in var.privatelink_endpoints : ep.region]))
    error_message = "All regions in privatelink_endpoints must be unique. Use privatelink_endpoints_single_region for multiple endpoints in the same region."
  }
}

variable "privatelink_endpoints_single_region" {
  type = list(object({
    region     = string
    subnet_ids = list(string)
    security_group = optional(object({
      ids                 = optional(list(string))
      create              = optional(bool, true)
      name_prefix         = optional(string, "atlas-privatelink-")
      inbound_cidr_blocks = optional(list(string))
      inbound_source_sgs  = optional(set(string), [])
      from_port           = optional(number, 1024)
      to_port             = optional(number, 65535)
    }), {})
    tags = optional(map(string), {})
  }))
  default     = []
  description = <<-EOT
    Single-region multi-endpoint pattern. Region accepts us-east-1 or US_EAST_1 format. All regions must MATCH.
    See [Port ranges used for private endpoints](https://www.mongodb.com/docs/atlas/security-private-endpoint/#port-ranges-used-for-private-endpoints) for port range details.
  EOT

  validation {
    condition     = length(var.privatelink_endpoints_single_region) == 0 || length(distinct([for ep in var.privatelink_endpoints_single_region : ep.region])) == 1
    error_message = "All regions in privatelink_endpoints_single_region must match (same region)."
  }

  validation {
    condition     = length(var.privatelink_endpoints_single_region) == 0 || length(var.privatelink_endpoints) == 0
    error_message = "Cannot use both privatelink_endpoints and privatelink_endpoints_single_region."
  }
}

variable "privatelink_byoe_regions" {
  type        = map(string)
  default     = {}
  description = "BYOE Phase 1: Key is user identifier, value is region (us-east-1 or US_EAST_1)."

  validation {
    condition     = length(setintersection(keys(var.privatelink_byoe_regions), [for ep in var.privatelink_endpoints : ep.region])) == 0
    error_message = "Regions in `privatelink_byoe_regions` must not overlap with regions in privatelink_endpoints."
  }
}

variable "privatelink_byoe" {
  type = map(object({
    vpc_endpoint_id = string
  }))
  default     = {}
  description = "BYOE Phase 2: Key must exist in `privatelink_byoe_regions`."

  validation {
    condition     = alltrue([for k in keys(var.privatelink_byoe) : contains(keys(var.privatelink_byoe_regions), k)])
    error_message = "All keys in `privatelink_byoe` must exist in `privatelink_byoe_regions`."
  }
}

variable "backup_export" {
  type = object({
    enabled     = optional(bool, false)
    bucket_name = optional(string)
    create_s3_bucket = optional(object({
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
    }), { enabled = false })
    iam_role = optional(object({
      create               = optional(bool, false)
      name                 = optional(string)
      path                 = optional(string, "/")
      permissions_boundary = optional(string)
    }), { create = false })
  })
  default     = {}
  description = <<-EOT
    Backup snapshot export to S3 configuration.

    Provide EITHER:
    - `bucket_name` (user-provided S3 bucket)
    - `create_s3_bucket.enabled = true` (module-managed S3 bucket)

    **Bucket Naming (when module-managed):**
    - `create_s3_bucket.name` - Exact bucket name (conflicts with name_prefix)
    - `create_s3_bucket.name_prefix` - Prefix with Terraform-generated suffix (max 37 chars)
    - Default: `atlas-backup-{project_id_suffix}-` when neither specified

    **Security Defaults (when module-managed):**
    - Versioning enabled for backup recovery
    - SSE with aws:kms for encryption at rest
    - All public access blocked

    When `iam_role.create = true`, creates a dedicated IAM role for backup export instead of using the shared role.
  EOT

  validation {
    condition     = !(var.backup_export.bucket_name != null && try(var.backup_export.create_s3_bucket.enabled, false))
    error_message = "Cannot use both bucket_name (user-provided) and create_s3_bucket.enabled = true (module-managed)."
  }

  validation {
    condition     = !var.backup_export.enabled || (var.backup_export.bucket_name != null || try(var.backup_export.create_s3_bucket.enabled, false))
    error_message = "backup_export.enabled = true requires bucket_name OR create_s3_bucket.enabled = true."
  }

  validation {
    condition     = !(try(var.backup_export.create_s3_bucket.name, null) != null && try(var.backup_export.create_s3_bucket.name_prefix, null) != null)
    error_message = "Cannot use both create_s3_bucket.name and create_s3_bucket.name_prefix."
  }

  validation {
    condition     = try(length(var.backup_export.create_s3_bucket.name_prefix), 0) <= 37
    error_message = "create_s3_bucket.name_prefix must be 37 characters or less. S3 bucket names are limited to 63 characters and Terraform adds a 26-character random suffix."
  }
}

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all AWS resources created by this module."
}
