resource "local_file" "kubespray_inventory" {
  filename = "${path.module}/inventory.ini"
  content = templatefile("${path.module}/kubespray-inventory.ini.tftpl", {
    k8s_nodes = proxmox_virtual_environment_vm.k8s_nodes
    jumpbox   = proxmox_virtual_environment_vm.jumpbox
  })
}

# This resource orchestrates the entire Kubespray deployment
resource "null_resource" "deploy_kubespray" {
  # This ensures deployment only starts after all VMs and the inventory file are ready.
  depends_on = [
    null_resource.configure_hosts_file,
    local_file.kubespray_inventory
  ]

  triggers = {
    inventory_content = local_file.kubespray_inventory.content
    script_hash       = filemd5("${path.module}/run_kubespray.sh")
  }

  # --- Connection to the Jumpbox ---
  # We use the bastion host method to reach the NAT'd jumpbox
  connection {
    type                = "ssh"
    host                = proxmox_virtual_environment_vm.jumpbox.ipv4_addresses[1][0]
    user                = "dev"
    password            = "dev"

    bastion_host        = var.virtual_environment_ip_address
    bastion_user        = "root"
    bastion_private_key = file("~/.ssh/id_rsa")
  }

  # --- Provisioner 1: Upload the deployment script ---
  provisioner "file" {
    source      = "${path.module}/run_kubespray.sh"
    destination = "/home/dev/run_kubespray.sh"
  }

  # --- Provisioner 2: Upload the generated inventory file ---
  provisioner "file" {
    source      = local_file.kubespray_inventory.filename
    destination = "/home/dev/inventory.ini" # Upload to a temporary location
  }

  # --- Provisioner 3: Execute the deployment script ---
  provisioner "remote-exec" {
    inline = [
      # Make the script executable
      "chmod +x /home/dev/run_kubespray.sh",
      
      # Execute the script in the background using nohup,
      # and redirect both stdout and stderr to a log file.
      "sudo nohup /home/dev/run_kubespray.sh > /home/dev/kubespray_deployment.log 2>&1 &",
      "sleep 1"
    ]
  }
}

output "kubespray_deployment_log" {
  description = "SSH into the jumpbox and run 'tail -f /home/dev/kubespray_deployment.log' to monitor progress."
  value       = "tail -f /home/dev/kubespray_deployment.log"
}