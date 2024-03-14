resource "local_file" "ansible_inventory" {
  depends_on = [
    # Commented out because module is disabled
    # module.clickhouse.server_ip
  ]

  content = templatefile("${path.module}/templates/ansible-inventory.tpl",
    { server_groups = var.server_groups }
  )
  filename = "${path.module}/inventories/inventory-${var.environment}.ini"
}

resource "null_resource" "ansible_update_known_hosts" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    working_dir = path.module
    command     = "./scripts/update_known_hosts.sh"
    environment = {
      INVENTORY_FILE   = "ansible/inventory.ini"
      KNOWN_HOSTS_FILE = "ansible/known_hosts"
    }
  }
}
