output "ooniapi_ooni_io_fqdn" {
  value = aws_route53_record.ooniapi.name
}

output "ooniapi_dns_name" {
  value = aws_alb.ooniapi.dns_name
}

output "ooniapi_listener_http_arn" {
  value = aws_alb_listener.ooniapi_listener_http.arn
}

output "ooniapi_listener_https_arn" {
  value = aws_alb_listener.ooniapi_listener_https.arn
}
