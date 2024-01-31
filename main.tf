# Provider
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.4.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 5.0.0"
    }
  }
}

# Module Parameter Store
module "parameter_store" {
  source          = "./modules/parameter_store"
  parameter_names = var.parameter_names
}

# Module ECS
module "ecs" {
  source      = "./modules/ecs"
  clustername = var.clustername
}

