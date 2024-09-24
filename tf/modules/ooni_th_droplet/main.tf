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

  lifecycle {
    create_before_destroy = true
  }
}

data "cloudinit_config" "ooni_th_docker" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-init-docker.yml", {
      monitoring_ip = "5.9.112.244",
      deployer_key  = var.deployer_key
    })
  }
}

resource "digitalocean_droplet" "ooni_th_docker" {
  image     = "ubuntu-24-04-x64"
  name      = "${var.name}-docker-${var.stage}-${count.index}"
  region    = var.instance_location
  size      = var.instance_size
  ipv6      = true
  ssh_keys  = var.ssh_keys
  user_data = data.cloudinit_config.ooni_th_docker.rendered
  count     = var.droplet_count

  lifecycle {
    create_before_destroy = true
  }
}
