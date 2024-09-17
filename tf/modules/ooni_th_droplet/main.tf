terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

data "cloudinit_config" "ooni_th" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-init.yml", {
      distro_id       = "ubuntu",
      distro_codename = "jammy"
    })
  }

}

resource "digitalocean_droplet" "ooni_th" {
  image     = "ubuntu-24-04-x64"
  name      = "${var.name}-${var.stage}-${count.index}"
  region    = var.instance_location
  size      = var.instance_size
  ipv6      = true
  ssh_keys  = var.ssh_keys
  user_data = data.cloudinit_config.ooni_th.rendered
  count     = var.droplet_count
}
