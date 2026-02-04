<!-- @generated
WARNING: This file is auto-generated. Do not edit directly.
Changes will be overwritten when documentation is regenerated.
Run 'just gen-examples' to regenerate.
-->
# AWS PrivateLink BYOE

<!-- BEGIN_GETTING_STARTED -->
## Prerequisites

If you are familiar with Terraform and already have a project configured in MongoDB Atlas, go to [commands](#commands).

To deploy MongoDB Atlas in AWS with Terraform, ensure you meet the following requirements:

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) to be able to run `terraform` [commands](#commands).
2. [Sign in](https://account.mongodb.com/account/login) or [create](https://account.mongodb.com/account/register) your MongoDB Atlas Account.
3. Configure your [authentication](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#authentication) method.

   **NOTE**: Service Accounts (SA) are the preferred authentication method. See [Grant Programmatic Access to an Organization](https://www.mongodb.com/docs/atlas/configure-api-access/#grant-programmatic-access-to-an-organization) in the MongoDB Atlas documentation for detailed instructions on configuring SA access to your project.

4. Use an existing [MongoDB Atlas project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) or [create a new Atlas project resource](#optional-create-a-new-atlas-project-resource).
5. Authenticate your AWS CLI (`aws configure`) or configure your IAM credentials.

## Commands

```sh
terraform init # this will download the required providers and create a `terraform.lock.hcl` file.
# configure authentication env-vars (MONGODB_ATLAS_XXX, AWS_XXX)
# configure your `vars.tfvars` with required variables
terraform apply -var-file vars.tfvars
# cleanup
terraform destroy -var-file vars.tfvars
```

## (Optional) Create a New Atlas Project Resource

```hcl
variable "org_id" {
  type    = string
  default = "{ORG_ID}" # REPLACE with your organization id, for example `65def6ce0f722a1507105aa5`.
}

resource "mongodbatlas_project" "this" {
  name   = "cluster-module"
  org_id = var.org_id
}
```

- Replace the `var.project_id` with `mongodbatlas_project.this.project_id` in the [main.tf](./main.tf) file.
<!-- END_GETTING_STARTED -->

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
  service_name       = module.atlas_aws.privatelink_service_info[local.ep1].atlas_endpoint_service_name
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

- If you have any feedback or trouble please open a GitHub issue.
