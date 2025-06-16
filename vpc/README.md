VPC module with transit gateway
===============================

Usage
-----

```terraform
    locals {
        name_prefix = "example"
        vpc_cidr    = "10.24.100.0/25"
        subnets = {
            a = {
                az   = "eu-north-1a"
                cidr = "10.24.100.0/26"
            }
            b = {
                az   = "eu-north-1b"
                cidr = "10.24.100.64/26"
            }
        }
    }

    module "vpc" {
        source             = "github.com/TeliaSoneraNorge/no-ordering-services-tf-modules//vpc?ref=v1.1.19"
        name_prefix        = local.name_prefix
        vpc_cidr           = local.vpc_cidr
        subnets            = local.subnets
        transit_gateway_id = "tgw-09932d11b70314ae7" # eu-north-1 transit gateway
    }
```