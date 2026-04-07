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
    create = optional(string, "30m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = {}
  description = "Timeout overrides. See root module timeouts variable."
}
