locals {
  main-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.main.endpoint}' --b64-cluster-ca '${aws_eks_cluster.main.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.main.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "aws_launch_configuration" "main" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.main-node.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "t3.small"
  name_prefix                 = "terraform-eks-main"
  security_groups             = [aws_security_group.main-node.id]
  user_data_base64            = base64encode(local.main-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  desired_capacity     = 3
  launch_configuration = aws_launch_configuration.main.id
  max_size             = 6
  min_size             = 1
  name                 = "terraform-eks-main"
  vpc_zone_identifier  = module.vpc.public_subnets
}