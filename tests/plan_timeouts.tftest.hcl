/*
  Timeouts are meta-arguments on legacy SDK resources (timeouts {}) and nested
  attributes on Framework resources (timeouts = {}). Neither is exposed as a
  plannable resource attribute, so we cannot assert on timeout values directly.
  We verify default values on the variable and rely on plan success to confirm
  the dynamic/conditional blocks are syntactically valid across all resource types.
*/

mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
}

run "timeouts_default_values" {
  command = plan
  assert {
    condition     = var.timeouts.create == "30m"
    error_message = "Expected create timeout default 30m"
  }
  assert {
    condition     = var.timeouts.update == "30m"
    error_message = "Expected update timeout default 30m"
  }
  assert {
    condition     = var.timeouts.delete == "30m"
    error_message = "Expected delete timeout default 30m"
  }
}

run "timeouts_custom_override" {
  command = plan
  variables {
    timeouts = { create = "1h" }
  }
  assert {
    condition     = var.timeouts.create == "1h"
    error_message = "Expected create timeout 1h when overridden"
  }
  assert {
    condition     = var.timeouts.update == "30m"
    error_message = "Expected update timeout default 30m when not overridden"
  }
  assert {
    condition     = var.timeouts.delete == "30m"
    error_message = "Expected delete timeout default 30m when not overridden"
  }
}

run "timeouts_explicit_null" {
  command = plan
  variables {
    timeouts = null
  }
  assert {
    condition     = var.timeouts == null
    error_message = "Expected timeouts to be null"
  }
}

run "timeouts_null_all_features" {
  command = plan
  variables {
    timeouts = null
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["us-east-1"]
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
    }
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "" }]
    }
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access module"
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module"
  }
}

run "timeouts_all_resources_plan_succeeds" {
  command = plan
  variables {
    privatelink_regional_mode = "auto"
    timeouts                  = { create = "45m", update = "45m", delete = "45m" }
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["us-east-1"]
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
    backup_export = {
      enabled          = true
      create_s3_bucket = { enabled = true }
    }
    log_integration = {
      enabled          = true
      create_s3_bucket = { enabled = true }
      integrations     = [{ log_types = ["MONGOD"], prefix_path = "" }]
    }
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
  assert {
    condition     = length(module.backup_export) == 1
    error_message = "Expected backup_export module (timeout path exercised)"
  }
  assert {
    condition     = length(module.log_integration) == 1
    error_message = "Expected log_integration module (timeout path exercised)"
  }
}
