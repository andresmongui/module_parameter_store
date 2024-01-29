provider "aws" {
  region = "us-east-1"
}

resource "aws_ssm_parameter" "parameter" {
  count       = length(var.parameter_names)
  name        = var.parameter_names[count.index]
  type        = "String"
  value       = templatefile("definitions/${var.parameter_names[count.index]}.json",{})
}


#value = templatefile("definitions/${var.parameter_name}.json",{})

