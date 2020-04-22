resource "aws_alb" "ui" {
  name = "${var.environment_name}-${var.user}-ui"
  subnets = ["${data.aws_subnet.public-subnet.id}", "${data.aws_subnet.public-subnet2.id}"]
  #enable_deletion_protection = true
  security_groups = ["${aws_security_group.tf-eks-node.id}", "${aws_security_group.eks-alb-sg.id}"]

  tags = "${
    map(
     "Name", "${var.environment_name}-ui",
     "App", "takeon",
     "kubernetes.io/cluster/${aws_eks_cluster.eks.name}", "owned",
    )
  }"
}

resource "aws_alb" "business-layer" {
  name = "${var.environment_name}-${var.user}-bl"
  subnets = ["${data.aws_subnet.public-subnet.id}", "${data.aws_subnet.public-subnet2.id}"]
  #enable_deletion_protection = true
  security_groups = ["${aws_security_group.tf-eks-node.id}", "${aws_security_group.eks-alb-sg.id}"]
  internal = true

  tags = "${
    map(
     "Name", "${var.environment_name}-ui",
     "App", "takeon",
     "kubernetes.io/cluster/${aws_eks_cluster.eks.name}", "owned",
    )
  }"
}

data "aws_route53_zone" "takeon-public" {
  name = "es-take-on.aws.onsdigital.uk."
}

resource "aws_route53_record" "takeon-type-A" {
  zone_id = "${data.aws_route53_zone.takeon-public.zone_id}"
  name = "${data.aws_route53_zone.takeon-public.name}"
  type    = "A"

  alias {
    evaluate_target_health = false
    name = "${aws_alb.ui.dns_name}"
    zone_id = "${aws_alb.ui.zone_id}"
  }

  allow_overwrite = true
}

resource "aws_lb_target_group" "takeon-ui-tg" {
  name     = "${var.environment_name}-${var.user}-ui-tg"
  # Kubernetes NodePort services are in range 30000-32767
  # Fixing it as otherwise it assigns it dynamically
  port     = 31000
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"
#   stickiness {
#     type = "lb_cookie"
#     enabled = false
#   }
  health_check {
    protocol            = "HTTP"
    port                = 31000
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 6
    matcher             = "200,301,302"
  }
}

resource "aws_lb_target_group" "takeon-bl-tg" {
  name     = "${var.environment_name}-${var.user}-bl-tg"
  # Kubernetes NodePort services are in range 30000-32767
  # Fixing it as otherwise it assigns it dynamically
  port     = 32000
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.vpc.id}"
#   stickiness {
#     type = "lb_cookie"
#     enabled = false
#   }
  health_check {
    protocol            = "HTTP"
    port                = 32000
    path                = "/service"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 6
    matcher             = "200,301,302"
    }
}

resource "aws_lb_listener" "takeon-listener" {
  load_balancer_arn = "${aws_alb.ui.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.takeon-ui-tg.arn}"
  }
}

resource "aws_lb_listener" "takeon-listener-bl" {
  load_balancer_arn = "${aws_alb.business-layer.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.takeon-bl-tg.arn}"
  }
}
