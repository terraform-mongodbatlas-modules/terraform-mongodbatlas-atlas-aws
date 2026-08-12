variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "role_id" {
  type        = string
  description = "Atlas cloud provider access role ID"
}

variable "iam_role_name" {
  type        = string
  default     = null
  description = "IAM role name for attaching KMS policy"
}

variable "skip_iam_policy_attachments" {
  type        = bool
  default     = false
  description = "Skip creating KMS IAM role policy. Must be plan-time known (not derived from resource attributes)."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "User-provided KMS key ARN"
}

variable "region" {
  type        = string
  default     = null
  description = "Region (us-east-1 or US_EAST_1). Defaults to AWS provider's region."
}

variable "create_kms_key" {
  type = object({
    enabled                 = bool
    alias                   = optional(string, "alias/atlas-encryption")
    deletion_window_in_days = optional(number, 7)
    enable_key_rotation     = optional(bool, true)
    policy_override         = optional(string)
    multi_region            = optional(bool, true)
    replica_regions         = optional(set(string), [])
  })
  default = {
    enabled = false
  }
  nullable    = false
  description = <<-EOT
    Module-managed KMS key configuration.

    Set `replica_regions` to every additional AWS region where Atlas nodes run (excluding the
    primary `region`). Omit or leave empty for single-region clusters.

    `multi_region` defaults to `true` (multi-Region primary CMK). Set `false` for a
    single-Region key; `replica_regions` must be empty when `multi_region` is `false`.
  EOT

  validation {
    condition = (
      !var.create_kms_key.enabled ||
      length(try(var.create_kms_key.replica_regions, [])) == 0 ||
      try(var.create_kms_key.multi_region, true)
    )
    error_message = "create_kms_key.replica_regions requires create_kms_key.multi_region = true."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}

variable "require_private_networking" {
  type        = bool
  default     = false
  description = "Require private networking for KMS"
}

variable "enabled_for_search_nodes" {
  type        = bool
  default     = true
  description = "Whether BYOK encryption at rest applies to dedicated search nodes. Module defaults to true (provider default is false) for secure-by-default."
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
