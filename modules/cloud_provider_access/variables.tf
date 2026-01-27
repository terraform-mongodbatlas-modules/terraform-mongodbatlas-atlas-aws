variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "purpose" {
  type        = string
  default     = "shared"
  description = "Role purpose for naming (max 9 chars), e.g., shared, encrypt, backup"
  validation {
    condition     = length(var.purpose) <= 9
    error_message = "purpose must be 9 characters or less (name_prefix limit is 32 chars, fixed prefix uses 23)"
  }
}

variable "iam_role_name" {
  type        = string
  default     = null
  description = "Custom IAM role name. When null, uses name_prefix mongodb-atlas-{project_id_suffix}-{purpose} with AWS-generated suffix."
  validation {
    condition     = var.iam_role_name == null || length(var.iam_role_name) <= 64
    error_message = "iam_role_name must be 64 characters or less (AWS IAM role name limit)"
  }
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
