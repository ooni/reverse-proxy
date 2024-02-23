output "server_fqdm" {
  value = local.clickhouse_hostname
}

output "server_ip" {
  value = aws_eip.clickhouse_ip.public_ip
}
