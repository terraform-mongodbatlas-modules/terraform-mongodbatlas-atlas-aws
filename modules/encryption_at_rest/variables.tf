variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "atlas_region" {
  type        = string
  description = "Atlas region (e.g., US_EAST_1)"
}

variable "aws_region" {
  type        = string
  default     = null
  nullable    = true
  description = "AWS region for KMS VPC endpoint. Defaults to the AWS provider's region if not specified."
}

#------------------------------------------------------------------------------
# KMS Key Configuration
#------------------------------------------------------------------------------

variable "create_kms_key" {
  type        = bool
  default     = false
  description = "Whether to create a new KMS key for Atlas encryption"
}

variable "aws_kms_key_arn" {
  type        = string
  default     = null
  nullable    = true
  description = "Existing AWS KMS key ARN. Required when create_kms_key is false."
}

variable "kms_key_alias" {
  type        = string
  default     = "mongodb-atlas-encryption"
  description = "Alias for the KMS key (without 'alias/' prefix)"
}

variable "kms_key_description" {
  type        = string
  default     = "Customer managed key for MongoDB Atlas encryption at rest"
  description = "Description for the KMS key"
}

variable "kms_key_deletion_window_days" {
  type        = number
  default     = 30
  description = "Number of days before KMS key deletion"
}

#------------------------------------------------------------------------------
# IAM Role Configuration
#------------------------------------------------------------------------------

variable "create_kms_iam_role" {
  type        = bool
  default     = false
  description = "Whether to create a dedicated IAM role for Atlas KMS encryption"
}

variable "existing_aws_iam_role_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Existing AWS IAM role name. Required when create_kms_iam_role is false."
}

variable "aws_iam_role_name" {
  type        = string
  default     = "atlas-kms-role"
  description = "Name for the IAM role when create_kms_iam_role is true"
}

variable "aws_iam_role_policy_name" {
  type        = string
  default     = "AtlasEncryptionAtRestPolicy"
  description = "Name for the IAM role policy"
}

#------------------------------------------------------------------------------
# Atlas Cloud Provider Access Authorization
#------------------------------------------------------------------------------

variable "atlas_role_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Atlas role ID from an existing cloud provider access authorization. If provided, the module will skip creating cloud_provider_access_setup and authorization resources."
}

#------------------------------------------------------------------------------
# Private Networking
#------------------------------------------------------------------------------

variable "private_networking" {
  type = object({
    require_private_networking         = optional(bool, false)
    create_atlas_private_endpoint      = optional(bool, false)
    create_aws_kms_vpc_endpoint        = optional(bool, false)
    vpc_endpoint_subnet_ids            = optional(set(string), [])
    create_security_group              = optional(bool, false)
    security_group_ids                 = optional(set(string), [])
    security_group_inbound_cidr_blocks = optional(list(string))
    security_group_name_prefix         = optional(string, "atlas-kms-endpoint-")
  })
  default = {
    require_private_networking    = false
    create_atlas_private_endpoint = false
    create_aws_kms_vpc_endpoint   = false
    create_security_group         = false
  }
  description = "Private networking configuration for encryption at rest"
}

#------------------------------------------------------------------------------
# Other Settings
#------------------------------------------------------------------------------

variable "enabled_for_search_nodes" {
  type        = bool
  default     = true
  description = "Whether to enable encryption at rest for Atlas Search nodes"
}

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to apply to created resources"
}
