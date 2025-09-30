resource "proxmox_virtual_environment_file" "user_data_cloud_config_jumpbox" {

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.virtual_environment_node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: jumpbox
    ssh_pwauth: yes
    timezone: Asia/Shanghai
    users:
      - name: dev
        passwd: "$6$rounds=4096$iFF7LuApTVkDAG1I$tuMSkmn0VjoKu7QFXE9qzo4TJIogsRgZ1fgj8cBs7kL3mWvL74LyEYUpiFrNR0HDiff6DV2kxbgwl0ap/M5Ul1"
        groups: [adm, sudo]
        lock_passwd: false
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
      - name: root
        ssh_authorized_keys:
          - ${trimspace(tls_private_key.jumpbox.public_key_openssh)}
    package_update: true
    packages:
      - qemu-guest-agent
      - net-tools
      - curl
      - git
      - python3-pip
      - python3-venv
    runcmd:
      - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      - systemctl restart ssh
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - echo "done" > /tmp/cloud-config.done

    # Section to write SSH keys for the jumpbox
    write_files:
      - path: /root/.ssh/id_rsa
        content: |
          ${indent(6, tls_private_key.jumpbox.private_key_pem)}
        permissions: '0600'
        owner: root:root
      - path: /root/.ssh/id_rsa.pub
        content: "${tls_private_key.jumpbox.public_key_openssh}"
        permissions: '0644'
        owner: root:root
    EOF

    file_name = "user-data-cloud-config-jumpbox.yaml"
  }
}