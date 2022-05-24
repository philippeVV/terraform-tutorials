# required provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Provider config
provider "aws" {
  shared_credentials_file = "$home/.aws/credentials"
  profile                 = "default"
  region                  = "ca-central-1"
}

# VPC 1
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

## Internet GateWay in vpc1
resource "aws_internet_gateway" "vpc1_igw" {
  vpc_id = aws_vpc.vpc1.id
}

## Security group
# resource "aws_security_group" "vpc1_sg" {
#   description = "Allow ssh connection to appServer"
#   vpc_id = aws_vpc.vpc1.id
#   ingress = [ {
#     description = "ssh"
#     from_port = 0
#     cidr_blocks = [aws_subnet.subnetA.cidr_block]
#     protocol = "tcp"
#     self = false
#     to_port = 22
#   } ]
# }

## Security assoc. to subnetA
# resource "aws_securit" "name" {
  
# }


## Subnet A
resource "aws_subnet" "subnetA" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ca-central-1a"
}

## route_table
resource "aws_route_table" "rtbA" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1_igw.id
  }
}

## assoc route_table
resource "aws_route_table_association" "rtbA_subnetA" {
  subnet_id = aws_subnet.subnetA.id
  route_table_id = aws_route_table.rtbA.id
}

### App Server
resource "aws_instance" "app_server" {
  #ubuntu-xenial-16.04-amd64-server-20210928
  ami           = "ami-03bcd79f25ca6b127"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnetA.id
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = var.instance_name
  }
}

### key pair
resource "aws_key_pair" "deployer" {
  key_name = "deployer_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIgBWd1mQiKZRtMMAezhM0i67LwdlB65PuQtJtmXzEb+BOzpJaD7b5hDhI47NzQ+l7oJtvGvxySI5MfpV7pU0aV6x87HfGjo0zd2WwtHS4yPnoXqfd9uhs/rSAmmPpJ68A15ji2e++7WTDf0/w95Lh2sultoOhzO9XWX+afYmcFPUAI7Q5EZbyje0jnh/xFl0GKWOxlJArUvRJgnswepOIzKy5g24Vn0FX3vr+Q+nya2nxrThtNKKRtdWFb7htj9UXtkhPhGv2ht7BZ2BjBaCCvoZXm8lK23QLZJ8Q8GEpnZEVk9C/jRNjc4iRPWHy8JxyeooP59uo9MZSHgfXCucLDkoKnzCRKpdV9G2B3n83fTI3cjlkcEEVe23apHC8va3mJJgvBlc4nXubixiPZ9BQ/mtOBnrkeiCNBCVTtfmsBSBwa1syobcuRV86d+MsLlsc2q32QEAXNcpGXqIaKEf5w2NexYQKijpG9V96S338CfV/SVUhORi41bPQadOI5+8= pvv@pvv"
}

### elastic ip
resource "aws_eip" "AppServerEIP" {
  vpc = true
}

### eip assoc
resource "aws_eip_association" "appServer_eip" {
  instance_id = aws_instance.app_server.id
  allocation_id = aws_eip.AppServerEIP.id
}