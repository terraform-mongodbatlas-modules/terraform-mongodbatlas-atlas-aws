variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = ""
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "S3 bucket name for backup exports. If null, uses auto-generated name with prefix."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow bucket deletion even if not empty"
}
