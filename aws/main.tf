# required provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15"
    }
  }
}

# Provider config
provider "aws" {
  profile                 = "default"
  shared_credentials_files = ["/home/pvv/.aws/credentials"]
  shared_config_files = ["/home/pvv/.aws/config"]
}

# VPC 1
resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/16"
}

## Internet GateWay in vpc1
resource "aws_internet_gateway" "vpc1_igw" {
  vpc_id = aws_vpc.vpc1.id
}




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
  #ubuntu-jammy-22.04-amd64-server-20220420
  ami           = "ami-0fb99f22ad0184043"
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

### Security group
resource "aws_security_group" "appServer_sg" {
  description = "Allow ssh connection to appServer"
  vpc_id = aws_vpc.vpc1.id
  ingress {
    description = "ssh"
    from_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    to_port = 22
  }
}

### Security assoc. to ec2
resource "aws_network_interface_sg_attachment" "appServer_sg_assoc" {
  security_group_id = aws_security_group.appServer_sg.id
  network_interface_id = aws_instance.app_server.primary_network_interface_id
}

## subnet B
resource "aws_subnet" "subnetB" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ca-central-1a"
}

## subnet B
resource "aws_subnet" "subnetC" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ca-central-1b"
}

## DB subnet group in two az for rds
resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = [aws_subnet.subnetB.id, aws_subnet.subnetC.id]
}

## Security group for RDS
resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    description = "From ec2 appServer sg only"
    from_port = 0
    to_port = 0
    protocol = -1
    security_groups = [aws_security_group.appServer_sg.id ]
  }
}

## Parameter group for RDS
resource "aws_db_parameter_group" "rds-test" {
  name = "rds-test"
  family = "postgres14"

  parameter {
    name = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "db" {
  identifier = "test-db"
  instance_class = "db.t3.micro"
  allocated_storage = 5
  engine = "postgres"
  engine_version = "14.2"
  username = "paul"
  password = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name = aws_db_parameter_group.rds-test.name
  skip_final_snapshot = true
}