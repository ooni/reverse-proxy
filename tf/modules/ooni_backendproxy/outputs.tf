output "autoscaling_group_id" {
  value = aws_autoscaling_group.oonibackend_proxy.id
}
output "alb_target_group_id" {
  value = aws_alb_target_group.oonibackend_proxy.id
}
