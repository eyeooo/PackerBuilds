variable "proxmox_api_url" {
  type = string
  default = "https://10.1.2.3:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type = string
  default = "root@pam!testtoken"
}

variable "proxmox_api_token_secret" {
  type = string
  default = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type = string
}
