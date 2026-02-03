variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = null
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "Exact S3 bucket name for backup exports. Mutually exclusive with bucket_name_prefix."
}

variable "bucket_name_prefix" {
  type        = string
  default     = null
  description = "S3 bucket name prefix for backup exports. If null, uses auto-generated prefix based on project ID. Mutually exclusive with bucket_name."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow bucket deletion even if not empty"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources"
  default     = {}
}
