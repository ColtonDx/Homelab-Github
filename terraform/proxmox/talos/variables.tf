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

# The same list the Talos playbooks read; address, gateway and the other network fields are used by the machine config, not here
variable "nodes" {
  description = "The cluster's nodes, built by build-project.yaml from the talos_cluster inventory group"
  type = list(object({
    name           = string
    vm_id          = number
    target_node    = string
    address        = optional(string)
    prefix         = optional(number)
    gateway        = optional(string)
    interface      = optional(string)
    role           = optional(string, "controlplane")
    install_disk   = optional(string)
    cores          = optional(number, 2)
    memory         = optional(number, 4096)
    os_disk_size   = optional(string, "32G")
    data_disk_size = optional(string, "100G")
    storage_pool   = optional(string)
    mac_address    = optional(string)
  }))

  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.name])) && length(var.nodes) == length(distinct([for n in var.nodes : n.vm_id]))
    error_message = "Every node needs a unique name and vm_id."
  }
}

variable "talos_iso" {
  type        = string
  description = "Proxmox volume ID of the Talos ISO, present on every node's host, e.g. local:iso/talos-amd64.iso"
}

variable "storage_pool" {
  type        = string
  description = "Storage for the OS and data disks, unless a node sets its own"
}

variable "bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "qemu_agent" {
  type        = bool
  description = "Enable the QEMU guest agent; only when the install image includes the qemu-guest-agent extension"
  default     = false
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "Talos node - Deployed by Terraform"
}
