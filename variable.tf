variable "aws_region" {
  description = "A região da AWS onde a instância EC2 será provisionada"
}

variable "vpc_id" {
  description = "Vpc id account"
}

variable "subnet_ids" {
  description = "Subnets ids"
  type = list(string)
}
