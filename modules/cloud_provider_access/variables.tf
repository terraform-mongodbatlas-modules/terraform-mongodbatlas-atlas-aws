variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "purpose" {
  type        = string
  default     = "shared"
  description = "Role purpose for naming: shared, encryption, backup-export"
}

variable "iam_role_name" {
  type        = string
  default     = null
  description = "Custom IAM role name. Default: atlas-{project_id_suffix}-{purpose}"
}

variable "iam_role_path" {
  type        = string
  default     = "/"
  description = "IAM role path"
}

variable "iam_role_permissions_boundary" {
  type        = string
  default     = null
  description = "ARN of permissions boundary policy"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
