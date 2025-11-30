variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

#------------------------------------------------------------------------------
# S3 Bucket Configuration
#------------------------------------------------------------------------------

variable "bucket_name" {
  type        = string
  description = "S3 bucket name (used for both new and existing buckets)"
}

variable "create_s3_bucket" {
  type        = bool
  description = "Create a new S3 bucket (false = use existing bucket with provided name)"
  default     = false
}

variable "prefix_path" {
  type        = string
  description = "Prefix path for the push-based log export"
  default     = ""
}

variable "log_retention_days" {
  type        = number
  description = "Number of days to retain logs in S3 before deletion. Only applies when create_s3_bucket is true."
  default     = 90
}

#------------------------------------------------------------------------------
# IAM Role Configuration
#------------------------------------------------------------------------------

variable "create_iam_role" {
  type        = bool
  default     = false
  description = "Whether to create a dedicated IAM role for push-based log export"
}

variable "aws_iam_role_name" {
  type        = string
  default     = "atlas-push-based-log-role"
  description = "Name for the IAM role when creating a new one"
}

variable "existing_iam_role_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Name of existing IAM role. Required when create_iam_role is false."
}

variable "atlas_role_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Atlas role ID from an existing cloud provider access authorization. Required when create_iam_role is false."
}

variable "bucket_policy_name" {
  type        = string
  description = "Name of the S3 bucket policy"
  default     = "AtlasPushBasedLogPolicy"
}

#------------------------------------------------------------------------------
# Common Configuration
#------------------------------------------------------------------------------

variable "aws_tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to apply to created resources"
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    update = optional(string)
  })
  default     = null
  nullable    = true
  description = "Custom timeouts for push-based log export resource operations"
}
