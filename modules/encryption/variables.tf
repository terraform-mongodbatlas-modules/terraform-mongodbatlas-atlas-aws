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
  description = "IAM role name for attaching KMS policy"
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "User-provided KMS key ARN"
}

variable "region" {
  type        = string
  default     = null
  description = "AWS region for KMS key (defaults to provider's region)"
}

variable "create_kms_key" {
  type = object({
    enabled                 = bool
    alias                   = optional(string, "alias/atlas-encryption")
    deletion_window_in_days = optional(number, 7)
    enable_key_rotation     = optional(bool, true)
    policy_override         = optional(string)
  })
  default = {
    enabled = false
  }
  nullable    = false
  description = "Module-managed KMS key configuration"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
