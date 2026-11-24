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

variable "target_node" {
  type        = string
  description = "Proxmox node the VM runs on"
}

variable "template_name" {
  type        = string
  description = "Cloud-init template to clone when building the VM from scratch"
}

variable "storage_pool" {
  type        = string
  description = "Storage for the OS and cloud-init disks"
}

variable "mac_address" {
  type        = string
  description = "MAC address to keep across rebuilds; empty lets Proxmox generate one"
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "VM name"
  default     = "Gametable"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VMID"
  default     = 5000
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "The Gametable project VM"
}

variable "cores" {
  type        = number
  description = "CPU cores"
  default     = 4
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 8192
}

variable "os_disk_size" {
  type        = string
  description = "OS disk size; can grow but never shrink"
  default     = "32G"
}

variable "bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "start_at_node_boot" {
  type        = bool
  description = "Start the VM when its Proxmox node boots"
  default     = false
}

variable "tags" {
  type        = string
  description = "Semicolon-separated Proxmox tags"
  default     = "terraform"
}

variable "adopt_existing_vm" {
  type        = bool
  description = "Import the VM that already has vm_id on target_node instead of creating it; set false when building it from scratch"
  default     = true
}
