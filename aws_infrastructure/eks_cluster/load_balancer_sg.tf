resource "aws_security_group" "eks-alb-sg" {
  name        = "${var.environment_name}-${var.user}-lb-sg"
  description = "Security group allowing public traffic for the eks load balancer."
  vpc_id      = "${data.aws_vpc.vpc.id}"
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = "${
    map(
     "Name", "${var.environment_name}-${var.user}-lb-sg",
     "App", "takeon",
     "kubernetes.io/cluster/${aws_eks_cluster.eks.name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-nlb-sg--ingress-workstation-https" {
  cidr_blocks       = ["${var.my_computer_ip}"]
  description       = "Allow workstation to communicate with the cluster API Server."
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-alb-sg.id}"
  to_port           = 80
  type              = "ingress"
}