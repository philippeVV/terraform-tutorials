

# Cluster
resource "aws_security_group" "eks" {
  name        = var.cluster_name
  description = "Cluster communication with worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = concat(module.vpc.public_subnets_cidr_blocks, var.vpn_cidr_block)
  }
}

# Worker nodes


resource "aws_security_group" "main-node" {
  name        = "terraform-eks-main-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "main-node-ingress-self" {
  type              = "ingress"
  description       = "Allow node to communicate with each other"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.main-node.id
  to_port           = 65535
  cidr_blocks       = concat(module.vpc.private_subnets_cidr_blocks, var.vpn_cidr_block)

}
