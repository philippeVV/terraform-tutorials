output "azs" {
  value = module.vpc.azs
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "vpc_id" {
  value = module.vpc.vpc_id
}