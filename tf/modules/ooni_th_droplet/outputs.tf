output "droplet_ipv4_address" {
  value = digitalocean_droplet.ooni_th[*].ipv4_address
}
