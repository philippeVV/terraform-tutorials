variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "cluster_name" {
  default = "terraform-eks"
  description = "EKS cluster name"
}

variable "vpn_cidr_block" {
  type = list
  default = ["0.0.0.0/0"]
}