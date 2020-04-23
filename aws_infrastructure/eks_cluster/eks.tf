# Import existing resources needed for EKS cluster creation
data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-vpc"]
  }
}

data "aws_security_group" "private-securitygroup" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-private-securitygroup"]
  }
}

data "aws_security_group" "public-securitygroup" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-public-securitygroup"]
  }
}

data "aws_subnet" "public-subnet" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-public-subnet"]
  }
}

data "aws_subnet" "public-subnet2" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-public-subnet2"]
  }
}

data "aws_subnet" "private-subnet" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-private-subnet"]
  }
}

data "aws_subnet" "private-subnet2" {
  filter {
    name = "tag:Name"
    values = ["${var.environment_name}-${var.user}-private-subnet2"]
  }
}

#IAM role and policy to allow the EKS service to manage or retrieve data from other AWS services
resource "aws_iam_role" "takeon-eks-master-role" {
  name = "${var.environment_name}-${var.user}-eks-master-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "take-on-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.takeon-eks-master-role.name}"
}

resource "aws_iam_role_policy_attachment" "take-on-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.takeon-eks-master-role.name}"
}


# EKS cluster
resource "aws_eks_cluster" "eks" {
    name = "${var.environment_name}-${var.user}-eks-cluster"
    role_arn = "${aws_iam_role.takeon-eks-master-role.arn}"
    enabled_cluster_log_types = "${var.eks_cluster_enabled_logs}"

    vpc_config {
        subnet_ids = ["${data.aws_subnet.public-subnet.id}", "${data.aws_subnet.public-subnet2.id}",
                      "${data.aws_subnet.private-subnet.id}", "${data.aws_subnet.private-subnet2.id}"]

    security_group_ids = ["${data.aws_security_group.private-securitygroup.id}"]
    #security_group_ids = ["${aws_security_group.tf-eks-master.id}"]
    }
}

# Worker node configuration

resource "aws_iam_role" "node-role" {
  name = "${var.environment_name}-${var.user}-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.node-role.name}"
}

resource "aws_iam_role_policy_attachment" "node-role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.node-role.name}"
}

resource "aws_iam_role_policy_attachment" "node-role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.node-role.name}"
}

# New
# An instance profile is a container 
# for an IAM role that you can use to pass role information to an EC2 instance when the instance starts.

resource "aws_iam_instance_profile" "node" {
  name = "${var.environment_name}-${var.user}-eks-node"
  role = "${aws_iam_role.node-role.name}"
}

# New
# Setup data source to get amazon-provided AMI for EKS nodes
# data "aws_ami" "eks-worker" {
#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-v*"]
#   }
 
#   most_recent = true
#   owners      = ["602401143452"] # Amazon EKS AMI Account ID
# }

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.13-v20190701"]
  }
 
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# New
locals {
  tf-eks-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks.certificate_authority.0.data}' '${aws_eks_cluster.eks.name}'
USERDATA
}
 
resource "aws_launch_configuration" "tf_eks" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t3.medium"
  name_prefix                 = "terraform-eks"
  security_groups             = ["${aws_security_group.tf-eks-node.id}"]
  user_data_base64            = "${base64encode(local.tf-eks-node-userdata)}"
  key_name                    = "takeon-dev-vpc-key"
 
  lifecycle {
    create_before_destroy = true
  }
}

# New
resource "aws_autoscaling_group" "tf_eks" {
  desired_capacity     = "2"
  launch_configuration = "${aws_launch_configuration.tf_eks.id}"
  max_size             = "3"
  min_size             = "1"
  name                 = "${var.environment_name}-${var.user}-asg"
  vpc_zone_identifier  = ["${data.aws_subnet.private-subnet.id}", "${data.aws_subnet.private-subnet2.id}"]
  target_group_arns = ["${aws_lb_target_group.takeon-ui-tg.arn}", "${aws_lb_target_group.takeon-bl-tg.arn}"]
 
  tag {
    key                 = "Name"
    value               = "${aws_eks_cluster.eks.name}-${var.user}-node"
    propagate_at_launch = true
  }

  tag {
  key                 = "App"
  value               = "takeon"
  propagate_at_launch = true
  }
 
  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.eks.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

# New
# our worker nodes try to register at our EKS master, but they are not accepted into the cluster. 
# We need to create a config map in our running Kubernetes cluster to accept them

//data "external" "aws_iam_authenticator" {
//  program = ["sh", "-c", "aws-iam-authenticator token -i ${aws_eks_cluster.eks.name} | jq -r -c .status"]
//}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = "${aws_eks_cluster.eks.name}"
}

provider "kubernetes" {
  host                      = "${aws_eks_cluster.eks.endpoint}"
  cluster_ca_certificate    = "${base64decode(aws_eks_cluster.eks.certificate_authority.0.data)}"
  token                     = "${data.aws_eks_cluster_auth.eks_cluster_auth.token}"
  load_config_file          = false
  version = "~> 1.5"
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<EOF
- rolearn: ${aws_iam_role.node-role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${aws_iam_role.takeon-eks-master-role.arn}
  username: admin:{{SessionName}}
  groups:
    - system:masters
EOF
  }
  depends_on = [
    "aws_eks_cluster.eks"  ]
}

resource "kubernetes_namespace" "test_namespace" {
  metadata {
    name = "${var.user}-test"
  }
}

# Generate Kubeconfig file
locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "example"
KUBECONFIG
}

