variable "vpc_id" {
  description = "The ID of the VPC to which the VPN will be associated."
}

variable "subnet_ids" {
  description = "A list of subnet ID to be reacheable from the VPN"
  type        = list(any)
}