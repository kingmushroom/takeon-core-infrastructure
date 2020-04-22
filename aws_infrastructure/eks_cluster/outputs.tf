output "ui_load_balancer" {
  value = "${aws_alb.ui.dns_name}"
}

output "business_layer_load_balancer" {
  value = "${aws_alb.business-layer.dns_name}"
}
 output "eks_kubeconfig" {
  value = "${local.kubeconfig}"
  depends_on = [
    "aws_eks_cluster.eks"
  ]
}

