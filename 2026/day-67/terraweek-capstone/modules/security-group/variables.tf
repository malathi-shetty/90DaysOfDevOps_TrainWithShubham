variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_ports" {
  description = "Ports allowed inbound"
  type        = list(number)
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}