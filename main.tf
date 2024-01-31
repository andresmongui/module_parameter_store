# Provider
provider "aws" {
  region = "us-east-1"
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
