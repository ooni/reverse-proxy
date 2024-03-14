output "alb_dns_name" {
  value = aws_alb.oonidataapi.dns_name
}

output "alb_zone_id" {
  value = aws_alb.oonidataapi.zone_id
}
