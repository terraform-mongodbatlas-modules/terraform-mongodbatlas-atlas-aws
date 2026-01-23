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
    require_private_networking = optional(bool, false)
    private_endpoint_regions   = optional(set(string), [])
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

    When `iam_role.create = true`, creates a dedicated IAM role for encryption instead of using the shared role.
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
    condition     = !var.encryption.require_private_networking || var.encryption.enabled
    error_message = "require_private_networking = true requires encryption.enabled = true."
  }
}

variable "privatelink_endpoints" {
  type = map(object({
    region             = optional(string)
    subnet_ids         = list(string)
    security_group_ids = optional(list(string))
    tags               = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
    Module-managed PrivateLink endpoints.

    Key is the user identifier (or AWS region if `region` is omitted).

    Example:
    ```hcl
    privatelink_endpoints = {
      us-east-1 = { subnet_ids = [aws_subnet.east.id] }
      us-west-2 = { subnet_ids = [aws_subnet.west.id] }
    }
    ```

    For custom keys:
    ```hcl
    privatelink_endpoints = {
      primary = { region = "us-east-1", subnet_ids = [aws_subnet.east.id] }
    }
    ```
  EOT
}

variable "privatelink_byoe_regions" {
  type        = map(string)
  default     = {}
  description = <<-EOT
    Atlas-side PrivateLink endpoints for BYOE (Bring Your Own Endpoint).
    Key is user identifier, value is AWS region.

    Use this for Phase 1 of BYOE pattern to get `endpoint_service_name` for creating
    VPC endpoints outside of Terraform.
  EOT

  validation {
    condition     = length(setintersection(keys(var.privatelink_byoe_regions), keys(var.privatelink_endpoints))) == 0
    error_message = "Keys in privatelink_byoe_regions must not overlap with keys in privatelink_endpoints."
  }
}

variable "privatelink_byoe" {
  type = map(object({
    vpc_endpoint_id             = string
    private_endpoint_ip_address = string
  }))
  default     = {}
  description = <<-EOT
    BYOE endpoint details. Key must exist in `privatelink_byoe_regions`.

    Provide after creating VPC endpoints externally using the `endpoint_service_name`
    from module output `privatelink_service_info`.
  EOT

  validation {
    condition     = alltrue([for k in keys(var.privatelink_byoe) : contains(keys(var.privatelink_byoe_regions), k)])
    error_message = "All keys in privatelink_byoe must exist in privatelink_byoe_regions."
  }
}

variable "backup_export" {
  type = object({
    enabled     = optional(bool, false)
    bucket_name = optional(string)
    create_s3_bucket = optional(object({
      enabled                 = bool
      name                    = optional(string)
      force_destroy           = optional(bool, false)
      versioning_enabled      = optional(bool, true)
      server_side_encryption  = optional(string, "aws:kms")
      block_public_acls       = optional(bool, true)
      block_public_policy     = optional(bool, true)
      ignore_public_acls      = optional(bool, true)
      restrict_public_buckets = optional(bool, true)
    }))
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
}

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all AWS resources created by this module."
}
