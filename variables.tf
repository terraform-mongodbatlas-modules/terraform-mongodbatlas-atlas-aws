variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "existing_aws_iam_role" {
  type = object({
    enabled = bool
    arn     = optional(string)
  })
  default = {
    enabled = false
    arn     = null
  }
  validation {
    condition     = !var.existing_aws_iam_role.enabled || var.existing_aws_iam_role.arn != null
    error_message = "arn must be provided when enabled is true"
  }
}

variable "aws_iam_role_name" {
  type        = string
  description = "Name for the shared AWS IAM role. Required when creating shared cloud provider access without an existing role."
  default     = null
  nullable    = true
}

variable "aws_iam_role_db_admin" {
  type = object({
    enabled     = bool
    role_arn    = string
    description = optional(string, "Atlas AWS IAM role for database admin")
    labels      = optional(map(string), {})
  })
  default = {
    enabled  = false
    role_arn = ""
  }
}

variable "encryption_at_rest" {
  type = object({
    enabled                  = bool
    create_kms_key           = optional(bool, false)
    create_kms_iam_role      = optional(bool, false)
    aws_kms_key_arn          = optional(string)
    kms_key_alias            = optional(string, "mongodb-atlas-encryption")
    kms_key_description      = optional(string, "Customer managed key for MongoDB Atlas encryption at rest")
    aws_iam_role_name        = optional(string, "atlas-kms-role")
    enabled_for_search_nodes = optional(bool, true)
    private_networking = optional(object({
      require_private_networking         = optional(bool, false)
      create_atlas_private_endpoint      = optional(bool, false)
      create_aws_kms_vpc_endpoint        = optional(bool, false)
      vpc_endpoint_subnet_ids            = optional(set(string), [])
      create_security_group              = optional(bool, false)
      security_group_ids                 = optional(set(string), [])
      security_group_inbound_cidr_blocks = optional(list(string))
      security_group_name_prefix         = optional(string, "atlas-kms-endpoint-")
      }), {
      require_private_networking    = false
      create_atlas_private_endpoint = false
      create_aws_kms_vpc_endpoint   = false
      create_security_group         = false
    })
  })
  default = {
    enabled             = false
    create_kms_key      = false
    create_kms_iam_role = false
  }
}

variable "push_based_log_export" {
  type = object({
    enabled            = bool
    create_iam_role    = optional(bool, false)
    aws_iam_role_name  = optional(string, "atlas-push-based-log-role")
    bucket_name        = optional(string)
    create_s3_bucket   = optional(bool, false)
    prefix_path        = optional(string, "")
    bucket_policy_name = optional(string, "AtlasPushBasedLogPolicy")
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      update = optional(string)
    }))
  })
  default = {
    enabled         = false
    create_iam_role = false
  }
}

variable "atlas_region" {
  type        = string
  description = "Atlas region, required when private link is enabled"
  default     = ""
}

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to apply to all created resources"
}

variable "privatelink" {
  type = object({
    enabled                            = bool
    create_vpc_endpoint                = optional(bool, false)
    existing_vpc_endpoint_id           = optional(string)
    subnet_ids                         = optional(set(string), [])
    security_group_ids                 = optional(set(string), [])
    create_security_group              = optional(bool, false)
    security_group_inbound_cidr_blocks = optional(list(string))
    security_group_name_prefix         = optional(string, "mongodb-privatelink-")
    tags                               = optional(map(string), {})
  })
  default = {
    enabled             = false
    create_vpc_endpoint = false
  }
  description = "PrivateLink configuration for MongoDB Atlas"

  validation {
    condition     = !var.privatelink.enabled || var.privatelink.create_vpc_endpoint || (var.privatelink.existing_vpc_endpoint_id != null && var.privatelink.existing_vpc_endpoint_id != "")
    error_message = "When privatelink is enabled and create_vpc_endpoint is false, existing_vpc_endpoint_id must be provided"
  }

  validation {
    condition     = !var.privatelink.enabled || !var.privatelink.create_vpc_endpoint || length(var.privatelink.subnet_ids) > 0
    error_message = "When privatelink is enabled and create_vpc_endpoint is true, subnet_ids must be provided"
  }

  validation {
    condition     = !var.privatelink.enabled || !var.privatelink.create_vpc_endpoint || var.privatelink.create_security_group || length(var.privatelink.security_group_ids) > 0
    error_message = "When creating a VPC endpoint, either create_security_group must be true or security_group_ids must be provided"
  }
}
