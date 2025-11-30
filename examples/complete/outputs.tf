output "project_id" {
  value       = mongodbatlas_project.this.id
  description = "MongoDB Atlas Project ID"
}

output "encryption_at_rest" {
  value       = module.atlas_aws.encryption_at_rest
  description = "Encryption at rest details"
  sensitive   = true
}

output "privatelink" {
  value       = module.atlas_aws.privatelink
  description = "Private endpoint details including security_group_id"
}
