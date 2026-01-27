<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# AWS PrivateLink BYOE

## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To use MongoDB Atlas with AWS through Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run the `terraform` commands
2. Sign up for a [MongoDB Atlas Account](https://www.mongodb.com/products/integrations/hashicorp-terraform)
3. Configure [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication)
4. An existing [MongoDB Atlas Project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project).
5. AWS CLI authenticated (`aws configure`) or IAM credentials configured

## Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, AWS_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

## Code Snippet

Copy and use this code to get started quickly:

**main.tf**
```hcl
# BYOE (Bring Your Own Endpoint) pattern
# 
# For BYOE, we use a two-step approach:
# Step 1: Root module creates Atlas-side PrivateLink endpoint and exposes service info
# Step 2: User-managed AWS VPC Endpoint references the Atlas service info (see below)
#
# Note: Step 2 (aws_vpc_endpoint.custom) depends on Step 1 output (privatelink_service_info)

# Step 1: Configure Atlas PrivateLink with BYOE regions

locals {
  ep1 = "ep1"
}

module "atlas_aws" {
  source  = "terraform-mongodbatlas-modules/atlas-aws/mongodbatlas"

  project_id = var.project_id

  # BYOE: provide your own VPC endpoint ID
  privatelink_byoe = {
    (local.ep1) = { vpc_endpoint_id = aws_vpc_endpoint.custom.id }
  }
  privatelink_byoe_regions = { (local.ep1) = var.aws_region }
}

# Step 2: User-managed AWS VPC Endpoint with custom configuration
resource "aws_vpc_endpoint" "custom" {
  vpc_id             = var.vpc_id
  service_name       = module.atlas_aws.privatelink_service_info[local.ep1].endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  tags = {
    Name = "atlas-privatelink-custom"
  }
}

output "privatelink" {
  description = "PrivateLink connection details"
  value       = module.atlas_aws.privatelink[local.ep1]
}

output "vpc_endpoint_id" {
  description = "VPC endpoint ID of the custom endpoint"
  value       = aws_vpc_endpoint.custom.id
}
```

**Additional files needed:**
- [variables.tf](./variables.tf)
- [versions.tf](./versions.tf)



## Feedback or Help

- If you have any feedback or trouble please open a GitHub issue
