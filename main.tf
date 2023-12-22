# Provider
provider "aws" {
  region = "us-east-1"
}

# Module
module "parameter_store" {
  source = "./modules"

  parameter_names = var.parameter_names
}

