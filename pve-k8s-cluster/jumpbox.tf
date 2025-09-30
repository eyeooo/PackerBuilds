resource "proxmox_virtual_environment_vm" "jumpbox" {
  name      = "jumpbox"
  node_name = var.virtual_environment_node_name

  clone {
    vm_id = proxmox_virtual_environment_vm.k8s_ubuntu_template.id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
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
    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config_jumpbox.id
  }

  network_device {
    bridge = "vmbr1"
  }

}

output "jumpbox_ipv4_address" {
  value = proxmox_virtual_environment_vm.jumpbox.ipv4_addresses[1][0]
}