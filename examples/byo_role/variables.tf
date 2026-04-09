variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = null
}

variable "atlas_role_id" {
  type        = string
  description = "Existing Atlas CPA role ID from IAM administrator"
}

variable "aws_iam_role_arn" {
  type        = string
  description = "ARN of the existing IAM role assumed by Atlas for CPA"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the existing KMS key"
}

variable "backup_bucket_name" {
  type        = string
  description = "Name of the existing S3 bucket for backup export"
}

variable "log_bucket_name" {
  type        = string
  description = "Name of the existing S3 bucket for log integration"
}
