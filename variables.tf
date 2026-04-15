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
    skip_iam_policy_attachments   = optional(bool, false)
    iam_role_name                 = optional(string)
    iam_role_path                 = optional(string, "/")
    iam_role_permissions_boundary = optional(string)
  })
  default     = {}
  description = <<-EOT
    Cloud provider access configuration for Atlas-AWS integration.

    **CPA operates in three modes:**

    1. `create = true` (default): Full module management. The module creates the
       AWS IAM role, the Atlas CPA setup and authorization, and attaches all IAM
       policies (s3:PutObject for backup/logs, KMS permissions for encryption).
    2. `create = false` + `existing`: BYO role. The module skips IAM role and
       Atlas CPA creation, uses the pre-existing `role_id` and `iam_role_arn`.
       The module still attaches IAM policies to the existing role.
    3. `create = false` + `skip_iam_policy_attachments = true` + `existing`:
       Read-only AWS mode. The module only creates Atlas-side resources. No IAM
       role creation, no IAM policy attachments. The IAM administrator must
       pre-attach all required policies externally.

    **Scope of `skip_iam_policy_attachments`:**
    - Applies only to the shared CPA role. Dedicated roles (`iam_role.create = true`
      on encryption, backup_export, or log_integration) always attach policies.
    - Features using the shared CPA role must use BYO resources; features using
      dedicated IAM roles may still use module-managed resources.
    - Subsumes `log_integration.kms_key_skip_iam_policy` when `true`.
    - The module validates these constraints.

    **IAM role options (mode 1 only):**
    - `iam_role_name`: Custom name (default: atlas-{project_id_suffix}-{purpose})
    - `iam_role_path`: IAM role path (default: /)
    - `iam_role_permissions_boundary`: ARN of permissions boundary policy
  EOT

  validation {
    condition     = var.cloud_provider_access.create || var.cloud_provider_access.existing != null
    error_message = "When cloud_provider_access.create = false, existing.role_id and existing.iam_role_arn are required."
  }

  validation {
    condition     = !var.cloud_provider_access.skip_iam_policy_attachments || !var.cloud_provider_access.create
    error_message = "skip_iam_policy_attachments = true requires create = false. The module cannot skip policies on a role it creates."
  }

  validation {
    condition     = !var.cloud_provider_access.skip_iam_policy_attachments || !try(var.encryption.enabled, false) || !try(var.encryption.create_kms_key.enabled, false) || try(var.encryption.iam_role.create, false)
    error_message = "skip_iam_policy_attachments = true requires BYO KMS key (kms_key_arn) or a dedicated encryption IAM role (encryption.iam_role.create = true)."
  }

  validation {
    condition     = !var.cloud_provider_access.skip_iam_policy_attachments || !try(var.backup_export.enabled, false) || !try(var.backup_export.create_s3_bucket.enabled, false) || try(var.backup_export.iam_role.create, false)
    error_message = "skip_iam_policy_attachments = true requires BYO S3 bucket (bucket_name) or a dedicated backup IAM role (backup_export.iam_role.create = true)."
  }

  validation {
    condition     = !var.cloud_provider_access.skip_iam_policy_attachments || !try(var.log_integration.enabled, false) || !try(var.log_integration.create_s3_bucket.enabled, false) || try(var.log_integration.iam_role.create, false)
    error_message = "skip_iam_policy_attachments = true requires BYO S3 bucket (bucket_name) or a dedicated log IAM role (log_integration.iam_role.create = true)."
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
    enabled_for_search_nodes = optional(bool, true)
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

    **Search Node Encryption:**
    `enabled_for_search_nodes` (default: `true`) controls whether BYOK encryption applies to dedicated search nodes. The module defaults to `true` (provider default is `false`) for a secure-by-default experience. Flipping from `false` to `true` on a deployment with dedicated search nodes triggers reprovisioning and index rebuild.

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
    condition     = length(var.privatelink_endpoints) == length(distinct([for ep in var.privatelink_endpoints : lower(replace(ep.region, "_", "-"))]))
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
    condition     = length(setintersection(keys(var.privatelink_byoe_regions), [for ep in var.privatelink_endpoints : lower(replace(ep.region, "_", "-"))])) == 0
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
      versioning_enabled      = optional(bool, false)
      server_side_encryption  = optional(string, "aws:kms")
      block_public_acls       = optional(bool, true)
      block_public_policy     = optional(bool, true)
      ignore_public_acls      = optional(bool, true)
      restrict_public_buckets = optional(bool, true)
      expiration_days         = optional(number, 365)
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
    - Versioning disabled (Atlas writes timestamp-based keys, no overwrite risk)
    - SSE with aws:kms for encryption at rest
    - All public access blocked

    **Lifecycle:**
    - `expiration_days` - Auto-delete objects after N days (default 365, 0 to disable)

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

  validation {
    condition     = try(var.backup_export.create_s3_bucket.name, null) == null || !strcontains(var.backup_export.create_s3_bucket.name, ".")
    error_message = "create_s3_bucket.name must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = try(var.backup_export.create_s3_bucket.name_prefix, null) == null || !strcontains(var.backup_export.create_s3_bucket.name_prefix, ".")
    error_message = "create_s3_bucket.name_prefix must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = var.backup_export.create_s3_bucket.expiration_days >= 0 && floor(var.backup_export.create_s3_bucket.expiration_days) == var.backup_export.create_s3_bucket.expiration_days
    error_message = "expiration_days must be a non-negative whole number. Use 0 to disable the lifecycle rule."
  }
}

variable "log_integration" {
  type = object({
    enabled = optional(bool, false)
    integrations = optional(list(object({
      log_types   = list(string)
      prefix_path = string
      bucket_name = optional(string)
    })), [])
    bucket_name = optional(string)
    create_s3_bucket = optional(object({
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
      expiration_days         = optional(number, 90)
    }), { enabled = false })
    kms_key                 = optional(string)
    kms_key_skip_iam_policy = optional(bool, false)
    tags                    = optional(map(string), {})
    iam_role = optional(object({
      create               = optional(bool, false)
      name                 = optional(string)
      path                 = optional(string, "/")
      permissions_boundary = optional(string)
    }), { create = false })
  })
  default     = {}
  description = <<-EOT
    Log integration configuration for exporting Atlas logs to S3.

    Provide EITHER:
    - `bucket_name` (user-provided S3 bucket, default for all integrations)
    - `create_s3_bucket.enabled = true` (module-managed S3 bucket)

    Per-integration `bucket_name` overrides are supported in addition to the
    root bucket above, but do not replace the requirement for a default bucket.

    **IAM Permissions (auto-attached to the CPA role):**
    The module attaches an IAM role policy with `s3:PutObject` and
    `s3:GetBucketLocation` for all target buckets (module-managed + BYO +
    per-integration overrides). No manual S3 policy setup is required.

    **Bucket Naming (when module-managed):**
    - `create_s3_bucket.name` - Exact bucket name (conflicts with name_prefix)
    - `create_s3_bucket.name_prefix` - Prefix with Terraform-generated suffix (max 37 chars)
    - Default: `atlas-logs-{project_id_suffix}-` when neither specified

    **KMS Encryption:**
    `kms_key` is the KMS key ARN passed to `mongodbatlas_log_integration` for
    Atlas-side log encryption before delivery to S3. This is separate from S3
    bucket server-side encryption (`create_s3_bucket.server_side_encryption`).
    The module attaches `kms:GenerateDataKey` + `kms:Decrypt` + `kms:DescribeKey` to the CPA role.
    Set `kms_key_skip_iam_policy = true` if the KMS key policy already grants access.

    **Integrations:**
    Each entry creates one `mongodbatlas_log_integration` resource.
    - `log_types` (required) - Valid values: MONGOD, MONGOS, MONGOD_AUDIT, MONGOS_AUDIT.
    - `prefix_path` (required) - S3 object key prefix for log delivery (e.g. "operational/", "audit/").
    - `bucket_name` (optional) - Per-integration bucket override.

    **S3 Lifecycle:**
    Module-managed buckets default to `expiration_days = 90`. Set to `0` to disable.
  EOT

  validation {
    condition     = !var.log_integration.enabled || length(var.log_integration.integrations) > 0
    error_message = "log_integration.enabled = true requires at least one entry in integrations."
  }

  validation {
    condition     = !var.log_integration.enabled || (var.log_integration.bucket_name != null || try(var.log_integration.create_s3_bucket.enabled, false))
    error_message = "log_integration.enabled = true requires bucket_name OR create_s3_bucket.enabled = true. Per-integration bucket_name overrides do not replace a default bucket."
  }

  validation {
    condition     = !(var.log_integration.bucket_name != null && try(var.log_integration.create_s3_bucket.enabled, false))
    error_message = "Cannot use both bucket_name (user-provided) and create_s3_bucket.enabled = true (module-managed)."
  }

  validation {
    condition     = !(try(var.log_integration.create_s3_bucket.name, null) != null && try(var.log_integration.create_s3_bucket.name_prefix, null) != null)
    error_message = "Cannot use both create_s3_bucket.name and create_s3_bucket.name_prefix."
  }

  validation {
    condition     = try(length(var.log_integration.create_s3_bucket.name_prefix), 0) <= 37
    error_message = "create_s3_bucket.name_prefix must be 37 characters or less. S3 bucket names are limited to 63 characters and Terraform adds a 26-character random suffix."
  }

  validation {
    condition     = try(var.log_integration.create_s3_bucket.name, null) == null || !strcontains(var.log_integration.create_s3_bucket.name, ".")
    error_message = "create_s3_bucket.name must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = try(var.log_integration.create_s3_bucket.name_prefix, null) == null || !strcontains(var.log_integration.create_s3_bucket.name_prefix, ".")
    error_message = "create_s3_bucket.name_prefix must not contain dot (.) characters. Dots in S3 bucket names are incompatible with virtual-hosted-style addressing required by Data Exfil Prevention."
  }

  validation {
    condition     = var.log_integration.create_s3_bucket.expiration_days >= 0 && floor(var.log_integration.create_s3_bucket.expiration_days) == var.log_integration.create_s3_bucket.expiration_days
    error_message = "expiration_days must be a non-negative whole number. Use 0 to disable the lifecycle rule."
  }
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = {}
  nullable    = true
  description = <<-EOT
    Timeout defaults applied to all wrapped resources (Atlas and AWS).
    Timeout strings use Go duration format (e.g., "30m", "1h").

    Set `timeouts = null` to skip all module-managed timeout blocks and use
    provider defaults. This is useful after `terraform import` to avoid plan
    diffs from timeout blocks that did not exist in the original configuration.

    - `timeouts = {}` or omitted: 30m create/update/delete (module defaults)
    - `timeouts = null`: no timeout blocks emitted (provider defaults)
    - `timeouts = { create = "1h" }`: custom create, 30m update/delete
  EOT
}

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all AWS resources created by this module."
}
