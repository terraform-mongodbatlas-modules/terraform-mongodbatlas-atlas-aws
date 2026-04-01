variable "project_id" {
  type        = string
  description = "MongoDB Atlas project ID"
}

variable "region" {
  type        = string
  description = "Region in either format (us-east-1 or US_EAST_1)"
}

variable "timeouts" {
  type = object({
    create                   = optional(string)
    delete                   = optional(string)
    delete_on_create_timeout = optional(bool)
  })
  default     = null
  description = "Timeout overrides for encryption_at_rest_private_endpoint. See root module timeouts variable."
}
