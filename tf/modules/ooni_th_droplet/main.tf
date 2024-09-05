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
    content      = file("${path.module}/templates/cloud-init.yml")
  }

}

resource "digitalocean_droplet" "ooni_th" {
  image     = "ubuntu-24-04-x64"
  name      = var.name
  region    = var.instance_location
  size      = var.instance_size
  user_data = data.cloudinit_config.ooni_th.rendered
  count     = var.droplet_count
}
