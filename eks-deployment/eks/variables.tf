variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "cluster_name" {
  default     = "terraform-eks"
  description = "EKS cluster name"
}

variable "vpn_cidr_block" {
  type    = list(any)
  default = ["10.20.0.0/22"]
}