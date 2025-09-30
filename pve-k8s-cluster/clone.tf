locals {
  node_hostnames = toset([
    "k8s-master-0",
    "k8s-worker-0",
    "k8s-worker-1",
  ])
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  for_each = local.node_hostnames

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.virtual_environment_node_name

  source_raw {
    data = templatefile("${path.module}/clone-cloud-config.yaml.tftpl", {
      hostname = each.value
      ssh_public_key = tls_private_key.jumpbox.public_key_openssh

    })

    file_name = "user-data-cloud-config-${each.value}.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  for_each = local.node_hostnames

  name      = each.value
  node_name = var.virtual_environment_node_name

  clone {
    vm_id = proxmox_virtual_environment_vm.k8s_ubuntu_template.id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8196
  }

  initialization {
    datastore_id = var.datastore_id
    dns {
      servers = ["8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config[each.key].id
  }

  network_device {
    bridge = "vmbr1"
  }

}

output "node_ipv4_addresses" {
  description = "A map of node hostnames to their primary IPv4 addresses."
  value = {
    for hostname, vm in proxmox_virtual_environment_vm.k8s_nodes :
    hostname => vm.ipv4_addresses[1][0]
  }
}