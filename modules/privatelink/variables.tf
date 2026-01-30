variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "region" {
  type        = string
  description = "Region (us-east-1 or US_EAST_1)"
}

variable "private_link_id" {
  type        = string
  description = "Atlas PrivateLink endpoint ID (from root module)"
}

variable "endpoint_service_name" {
  type        = string
  description = "Atlas endpoint service name (from root module)"
}

variable "vpc_endpoint" {
  type = object({
    create     = bool
    subnet_ids = optional(list(string), [])
  })
  default     = { create = false }
  description = "VPC endpoint config. create=true for module-managed, create=false for BYOE. subnet_ids is required when create=true."

  validation {
    condition     = !var.vpc_endpoint.create || length(var.vpc_endpoint.subnet_ids) > 0
    error_message = "vpc_endpoint.subnet_ids is required when vpc_endpoint.create = true."
  }
}

variable "byo_vpc_endpoint_id" {
  type        = string
  default     = null
  description = "BYO (Bring Your Own) VPC endpoint ID. Required when vpc_endpoint.create = false."

  validation {
    condition     = var.vpc_endpoint.create || var.byo_vpc_endpoint_id != null
    error_message = "byo_vpc_endpoint_id is required when vpc_endpoint.create = false (BYO mode)."
  }
}

variable "security_group" {
  type = object({
    ids                 = optional(list(string))
    create              = optional(bool, true)
    name_prefix         = optional(string, "atlas-privatelink-")
    inbound_cidr_blocks = optional(list(string)) # null = VPC CIDR, [] = no rule
    inbound_source_sgs  = optional(set(string), [])
    from_port           = optional(number, 1024)
    to_port             = optional(number, 65535)
  })
  default     = {}
  description = "Security group configuration. When ids is null and create is true, creates a security group."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS resources"
}
