/*
  Timeouts are meta-arguments on legacy SDK resources (timeouts {}) and nested
  attributes on Framework resources (timeouts = {}). Neither is exposed as a
  plannable resource attribute, so we cannot assert on timeout values directly.
  We verify delete_on_create_timeout (a regular schema attribute) and rely on
  plan success to confirm the dynamic/conditional blocks are syntactically valid.
  Submodule resource attributes are also inaccessible from root-level assertions.
*/

mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
}

run "timeouts_default_all_null" {
  command = plan
  variables {
    project_id = var.project_id
  }
  assert {
    condition     = var.timeouts.privatelink_regional_mode == null
    error_message = "Expected privatelink_regional_mode timeout to default to null"
  }
  assert {
    condition     = var.timeouts.cloud_provider_access == null
    error_message = "Expected cloud_provider_access timeout to default to null"
  }
  assert {
    condition     = var.timeouts.privatelink_endpoint == null
    error_message = "Expected privatelink_endpoint timeout to default to null"
  }
  assert {
    condition     = var.timeouts.privatelink_endpoint_service == null
    error_message = "Expected privatelink_endpoint_service timeout to default to null"
  }
  assert {
    condition     = var.timeouts.encryption_private_endpoint == null
    error_message = "Expected encryption_private_endpoint timeout to default to null"
  }
}

run "timeouts_privatelink_endpoint_on_resource" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      privatelink_endpoint = { create = "2h", delete = "2h", delete_on_create_timeout = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = mongodbatlas_privatelink_endpoint.this["us-east-1"].delete_on_create_timeout == true
    error_message = "Expected delete_on_create_timeout set on privatelink_endpoint resource"
  }
}

run "timeouts_privatelink_endpoint_null_delete_on_create" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      privatelink_endpoint = { create = "2h" }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = mongodbatlas_privatelink_endpoint.this["us-east-1"].delete_on_create_timeout == null
    error_message = "Expected delete_on_create_timeout null when not set"
  }
}

run "timeouts_all_resources_plan_succeeds" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      cloud_provider_access        = { create = "45m", delete_on_create_timeout = true }
      encryption_private_endpoint  = { create = "30m", delete = "30m", delete_on_create_timeout = true }
      privatelink_endpoint         = { create = "2h", delete = "2h", delete_on_create_timeout = true }
      privatelink_endpoint_service = { create = "2h", delete = "2h", delete_on_create_timeout = true }
      privatelink_regional_mode    = { create = "1h", update = "1h", delete = "1h" }
    }
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["us-east-1"]
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = mongodbatlas_privatelink_endpoint.this["us-east-1"].delete_on_create_timeout == true
    error_message = "Expected delete_on_create_timeout on privatelink_endpoint"
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access module (timeout path exercised)"
  }
  assert {
    condition     = length(module.encryption_private_endpoint) == 1
    error_message = "Expected encryption_private_endpoint module (timeout path exercised)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules (timeout path exercised)"
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 1
    error_message = "Expected regional_mode resource (timeout path exercised)"
  }
}

run "timeouts_all_null_no_plan_churn" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts   = {}
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = mongodbatlas_privatelink_endpoint.this["us-east-1"].delete_on_create_timeout == null
    error_message = "Expected null delete_on_create_timeout with empty timeouts"
  }
  assert {
    condition     = length(module.cloud_provider_access) == 0
    error_message = "Expected no cloud_provider_access with privatelink-only"
  }
}
