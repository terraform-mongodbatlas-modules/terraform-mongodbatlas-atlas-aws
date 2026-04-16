mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
}


run "privatelink_cross_region_same_as_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], service_region = "us-east-1" }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

run "privatelink_cross_region_invalid_service_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"] },
      { region = "us-west-2", subnet_ids = ["subnet-def"], service_region = "eu-west-1" }
    ]
  }
  expect_failures = [var.privatelink_endpoints]
}

run "privatelink_cross_region_valid" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], service_region = "us-east-1", security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional mode disabled for cross-region (single Atlas service region)"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected 1 Atlas endpoint (primary only)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules (primary + cross-region)"
  }
}

run "privatelink_cross_region_atlas_format" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "US_EAST_1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "US_WEST_2", subnet_ids = ["subnet-def"], service_region = "US_EAST_1", security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional mode disabled for cross-region (Atlas format)"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected 1 Atlas endpoint (primary only)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules (primary + cross-region)"
  }
}

run "privatelink_multi_region_with_cross_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "eu-west-1", subnet_ids = ["subnet-def"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-ghi"], service_region = "us-east-1", security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = output.regional_mode_enabled == true
    error_message = "Expected regional mode enabled (2 distinct Atlas service regions)"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 2
    error_message = "Expected 2 Atlas endpoints (us-east-1 + eu-west-1)"
  }
  assert {
    condition     = length(module.privatelink) == 3
    error_message = "Expected 3 privatelink modules (all entries)"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# BYOE Cross-Region Validation Tests
# ─────────────────────────────────────────────────────────────────────────────

run "byoe_cross_region_missing_service_region_key" {
  command = plan
  variables {
    project_id               = var.project_id
    privatelink_byoe_regions = { east = { region = "us-east-1" } }
    privatelink_byoe = {
      cross_west = { vpc_endpoint_id = "vpce-abc", region = "us-west-2" }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "byoe_cross_region_invalid_service_region_key" {
  command = plan
  variables {
    project_id               = var.project_id
    privatelink_byoe_regions = { east = { region = "us-east-1" } }
    privatelink_byoe = {
      cross_west = { vpc_endpoint_id = "vpce-abc", region = "us-west-2", service_region_key = "nonexistent" }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "byoe_cross_region_missing_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      east = { region = "us-east-1", supported_remote_regions = ["us-west-2"] }
    }
    privatelink_byoe = {
      cross_west = { vpc_endpoint_id = "vpce-abc", service_region_key = "east" }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "byoe_cross_region_region_not_in_supported" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      east = { region = "us-east-1", supported_remote_regions = ["eu-west-1"] }
    }
    privatelink_byoe = {
      cross_west = { vpc_endpoint_id = "vpce-abc", region = "us-west-2", service_region_key = "east" }
    }
  }
  expect_failures = [var.privatelink_byoe]
}

run "byoe_cross_region_valid" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      east = { region = "us-east-1", supported_remote_regions = ["us-west-2"] }
    }
    privatelink_byoe = {
      east       = { vpc_endpoint_id = "vpce-east" }
      cross_west = { vpc_endpoint_id = "vpce-west", region = "us-west-2", service_region_key = "east" }
    }
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected 1 Atlas endpoint (east only)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules (same-region + cross-region)"
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Expected regional mode disabled (single Atlas service region)"
  }
}

run "byoe_cross_region_does_not_trigger_regional_mode" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      east = { region = "us-east-1", supported_remote_regions = ["us-west-2", "eu-west-1"] }
    }
    privatelink_byoe = {
      east       = { vpc_endpoint_id = "vpce-east" }
      cross_west = { vpc_endpoint_id = "vpce-west", region = "us-west-2", service_region_key = "east" }
      cross_eu   = { vpc_endpoint_id = "vpce-eu", region = "eu-west-1", service_region_key = "east" }
    }
  }
  assert {
    condition     = output.regional_mode_enabled == false
    error_message = "Cross-region BYOE entries should not trigger regional mode"
  }
  assert {
    condition     = length(mongodbatlas_privatelink_endpoint.this) == 1
    error_message = "Expected 1 Atlas endpoint"
  }
  assert {
    condition     = length(module.privatelink) == 3
    error_message = "Expected 3 privatelink modules"
  }
}
