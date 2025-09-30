locals {
  all_nodes_ips = merge(
    { for hostname, vm in proxmox_virtual_environment_vm.k8s_nodes : hostname => vm.ipv4_addresses[1][0] },
    { "jumpbox" = proxmox_virtual_environment_vm.jumpbox.ipv4_addresses[1][0] }
  )

  hosts_file_content = join("\n", [
    for hostname, ip in local.all_nodes_ips :
    "${ip} ${hostname}" if ip != null
  ])
}

# This resource will run the provisioner after all VMs are created.
resource "null_resource" "configure_hosts_file" {
  # This depends_on is crucial.
  depends_on = [
    proxmox_virtual_environment_vm.k8s_nodes,
    proxmox_virtual_environment_vm.jumpbox
  ]

  # We use a for_each to run the provisioner on every single node.
  for_each = local.all_nodes_ips

  provisioner "remote-exec" {
    inline = [
      # Ensure the hosts content is not added multiple times on re-runs
      "grep -qF '${each.key}' /etc/hosts || sudo bash -c 'echo \"${local.hosts_file_content}\" >> /etc/hosts'"
    ]

    connection {
      # --- Target VM Configuration (using dev user/password) ---
      type     = "ssh"
      host     = each.value
      user     = "dev"
      password = "dev"

      # --- Bastion Host Configuration (using private key) ---
      bastion_host        = var.virtual_environment_ip_address
      bastion_user        = "root"
      bastion_private_key = file("~/.ssh/id_rsa") # IMPORTANT: Ensure this is the correct path to your key for the Proxmox host
    }
  }
}