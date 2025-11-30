# MongoDB Atlas PrivateLink Module

Configures AWS PrivateLink for MongoDB Atlas, enabling private connectivity between your VPC and Atlas clusters.

## Usage

```hcl
module "privatelink" {
  source = "./modules/privatelink"

  project_id   = "your-atlas-project-id"
  atlas_region = "US_EAST_1"

  # Create new VPC endpoint with managed security group
  create_vpc_endpoint   = true
  subnet_ids            = ["subnet-xxx", "subnet-yyy"]
  create_security_group = true
}
```

## Use Cases

The module supports two primary modes via the `create_vpc_endpoint` flag:

| `create_vpc_endpoint` | Description |
|-----------------------|-------------|
| `true` | Create a new VPC endpoint (requires `subnet_ids`) |
| `false` | Use an existing VPC endpoint (requires `existing_vpc_endpoint_id`) |

### Security Group Options

When `create_security_group = true`, the module creates a security group with ingress rules for MongoDB Atlas traffic (ports 27015-27017).

| `security_group_inbound_cidr_blocks` | `security_group_inbound_source_sgs` | Result |
|--------------------------------------|-------------------------------------|--------|
| `null` (default) | `[]` | Ingress from VPC CIDR |
| `["10.0.0.0/8"]` | `[]` | Ingress from specified CIDRs |
| `[]` | `["sg-xxx"]` | Ingress from specified security groups only |
| `["10.0.0.0/8"]` | `["sg-xxx"]` | Ingress from both CIDRs and security groups |
| `[]` | `[]` | No ingress rules created |

## Examples

### Create VPC Endpoint with Default Security Group

```hcl
module "privatelink" {
  source = "./modules/privatelink"

  project_id            = "your-atlas-project-id"
  atlas_region          = "US_EAST_1"
  create_vpc_endpoint   = true
  subnet_ids            = ["subnet-xxx"]
  create_security_group = true
  # Defaults to VPC CIDR for ingress
}
```

### Create VPC Endpoint with Source Security Groups

```hcl
module "privatelink" {
  source = "./modules/privatelink"

  project_id                        = "your-atlas-project-id"
  atlas_region                      = "US_EAST_1"
  create_vpc_endpoint               = true
  subnet_ids                        = ["subnet-xxx"]
  create_security_group             = true
  security_group_inbound_cidr_blocks = []  # Disable CIDR-based rules
  security_group_inbound_source_sgs  = ["sg-app-servers", "sg-bastion"]
}
```

### Use Existing VPC Endpoint

```hcl
module "privatelink" {
  source = "./modules/privatelink"

  project_id               = "your-atlas-project-id"
  atlas_region             = "US_EAST_1"
  create_vpc_endpoint      = false
  existing_vpc_endpoint_id = "vpce-xxx"
}
```

### Bring Your Own Security Group

When creating your own security group, use the `mongodb_port_range` output for the correct port configuration:

```hcl
module "privatelink" {
  source = "./modules/privatelink"

  project_id          = "your-atlas-project-id"
  atlas_region        = "US_EAST_1"
  create_vpc_endpoint = true
  subnet_ids          = ["subnet-xxx"]
  security_group_ids  = [aws_security_group.custom.id]
}

resource "aws_security_group" "custom" {
  name_prefix = "mongodb-atlas-"
  vpc_id      = "vpc-xxx"
}

resource "aws_security_group_rule" "mongodb_ingress" {
  type              = "ingress"
  from_port         = module.privatelink.mongodb_port_range.from_port
  to_port           = module.privatelink.mongodb_port_range.to_port
  protocol          = module.privatelink.mongodb_port_range.protocol
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.custom.id
}
```

## Outputs

| Name | Description |
|------|-------------|
| `aws_vpc_endpoint_id` | ID of the VPC endpoint (created or existing) |
| `aws_region` | AWS region |
| `aws_vpc_cidr_block` | CIDR block of the VPC |
| `security_group_id` | ID of the created security group (null if not created) |
| `mongodb_port_range` | Port range object for MongoDB Atlas traffic (`from_port`, `to_port`, `protocol`) |
| `atlas_private_endpoint_status` | Status of the Atlas private endpoint |
| `atlas_private_link_service_name` | Atlas PrivateLink service name |
| `atlas_private_link_service_resource_id` | Atlas PrivateLink service resource ID |
