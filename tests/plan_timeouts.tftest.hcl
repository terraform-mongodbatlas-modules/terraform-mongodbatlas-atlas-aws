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
    condition     = var.timeouts.regional_mode == null
    error_message = "Expected regional_mode timeout to default to null"
  }
  assert {
    condition     = var.timeouts.cloud_provider_access == null
    error_message = "Expected cloud_provider_access timeout to default to null"
  }
}

run "timeouts_regional_mode_threaded" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      regional_mode = { create = "45m", update = "45m", delete = "45m" }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(mongodbatlas_private_endpoint_regional_mode.this) == 1
    error_message = "Expected regional mode resource"
  }
}

run "timeouts_privatelink_endpoint_threaded" {
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
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected privatelink endpoint resource"
  }
}

run "timeouts_cloud_provider_access_threaded" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      cloud_provider_access = { create = "30m", delete_on_create_timeout = true }
    }
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected cloud_provider_access module"
  }
}

run "timeouts_encryption_private_endpoint_threaded" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      encryption_private_endpoint = { create = "30m", delete = "30m" }
    }
    encryption = {
      enabled                  = true
      kms_key_arn              = "arn:aws:kms:us-east-1:123456789012:key/abc"
      private_endpoint_regions = ["us-east-1"]
    }
  }
  assert {
    condition     = length(module.encryption_private_endpoint) == 1
    error_message = "Expected encryption private endpoint module"
  }
}

run "timeouts_privatelink_endpoint_service_threaded" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts = {
      privatelink_endpoint_service = { create = "3h", delete = "3h", delete_on_create_timeout = true }
    }
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(module.privatelink) == 1
    error_message = "Expected privatelink module"
  }
}

run "timeouts_all_null_no_plan_churn" {
  command = plan
  variables {
    project_id = var.project_id
    timeouts   = {}
  }
  assert {
    condition     = length(module.cloud_provider_access) == 1
    error_message = "Expected default cloud_provider_access module"
  }
}
