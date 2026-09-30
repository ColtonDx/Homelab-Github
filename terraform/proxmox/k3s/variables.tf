variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL, e.g. https://pve.example.com:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID, e.g. terraform@pve!terraform"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "nodes" {
  description = "The cluster's nodes, from terraform_k3s.nodes in the inventory; use an odd number, at least three, for etcd"
  type = list(object({
    name           = string
    vmid           = number
    proxmox_node   = string
    address        = string
    cores          = optional(number, 2)
    memory         = optional(number, 8192)
    os_disk_size   = optional(string, "32G")
    data_disk_size = optional(string, "100G")
    storage_pool   = optional(string)
  }))

  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.name])) && length(var.nodes) == length(distinct([for n in var.nodes : n.vmid]))
    error_message = "Every node needs a unique name and vmid."
  }
}

variable "gateway" {
  type        = string
  description = "Default gateway for the node subnet"
}

variable "ip_prefix" {
  type        = number
  description = "Subnet prefix length"
  default     = 24
}

variable "storage_pool" {
  type        = string
  description = "Storage for the VM disks, unless a node sets its own"
}

variable "template_name" {
  type        = string
  description = "Cloud-init template to clone; must exist on every Proxmox host the nodes use, since node-local storage cannot clone across hosts"
}

variable "ci_user" {
  type        = string
  description = "The user cloud-init creates, matching the one Ansible connects as; only applied on first boot"
}

variable "ssh_public_keys" {
  type        = string
  description = "Extra SSH public keys for ci_user, one per line; optional when the template already carries one"
  default     = ""
}

variable "bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "K3s server node (control plane, worker and storage) - Deployed by Terraform"
}
