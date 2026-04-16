mock_provider "mongodbatlas" {}
mock_provider "aws" {}

variables {
  project_id = "000000000000000000000000"
}

run "root_vpc_data_sources_created_for_module_managed" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(data.aws_subnet.privatelink) == 1
    error_message = "Expected root subnet data source for module-managed endpoint"
  }
  assert {
    condition     = length(data.aws_vpc.privatelink) == 1
    error_message = "Expected root VPC data source for module-managed endpoint"
  }
}

run "root_vpc_data_sources_for_cross_region" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } },
      { region = "us-west-2", subnet_ids = ["subnet-def"], service_region = "us-east-1", security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
  }
  assert {
    condition     = length(data.aws_subnet.privatelink) == 2
    error_message = "Expected root subnet data source for both module-managed endpoints"
  }
  assert {
    condition     = length(data.aws_vpc.privatelink) == 2
    error_message = "Expected root VPC data source for both module-managed endpoints"
  }
}

run "no_root_vpc_data_sources_for_byoe" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_byoe_regions = {
      primary = { region = "us-east-1" }
    }
    privatelink_byoe = {
      primary = { vpc_endpoint_id = "vpce-0123456789abcdef0" }
    }
  }
  assert {
    condition     = length(data.aws_subnet.privatelink) == 0
    error_message = "Expected no root subnet data source for BYOE"
  }
  assert {
    condition     = length(data.aws_vpc.privatelink) == 0
    error_message = "Expected no root VPC data source for BYOE"
  }
}

run "mixed_module_managed_and_byoe" {
  command = plan
  variables {
    project_id = var.project_id
    privatelink_endpoints = [
      { region = "us-east-1", subnet_ids = ["subnet-abc"], security_group = { inbound_cidr_blocks = ["10.0.0.0/8"] } }
    ]
    privatelink_byoe_regions = {
      secondary = { region = "eu-west-1" }
    }
    privatelink_byoe = {
      secondary = { vpc_endpoint_id = "vpce-fedcba9876543210f" }
    }
  }
  assert {
    condition     = length(data.aws_subnet.privatelink) == 1
    error_message = "Expected root subnet data source only for module-managed (not BYOE)"
  }
  assert {
    condition     = length(module.privatelink) == 2
    error_message = "Expected 2 privatelink modules (module-managed + BYOE)"
  }
}
