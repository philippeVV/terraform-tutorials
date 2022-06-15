provider "aws" {
  region = "us-east-2"
}

resource "aws_acm_certificate" "vpn_server" {
  private_key       = file("./certs/server.vpn.velz3n.com.key")
  certificate_body  = file("./certs/server.vpn.velz3n.com.crt")
  certificate_chain = file("./certs/ca.crt")
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Client VPN"
  client_cidr_block      = "10.20.0.0/22"
  split_tunnel           = true
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  security_group_ids     = [aws_security_group.vpn_access.id]
  vpc_id = var.vpc_id

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_server.arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_security_group" "vpn_access" {
  vpc_id = var.vpc_id
  name   = "vpn-sg"

  ingress {
    from_port   = 443
    protocol    = "UDP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming VPN connection"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnets" {
  count                  = length(var.subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = element(var.subnet_ids, count.index)


  lifecycle {
    // The issue why we are ignoring changes is that on every change
    // terraform screws up most of the vpn assosciations
    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
    ignore_changes = [subnet_id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(var.subnet_ids)

  id = each.value

}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  for_each = data.aws_subnet.selected

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = each.value.cidr_block
  authorize_all_groups   = true
}