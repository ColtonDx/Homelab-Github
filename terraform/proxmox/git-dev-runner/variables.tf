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

variable "ip_address" {
  type        = string
  description = "Static IPv4 address, without the prefix"
}

variable "gateway" {
  type        = string
  description = "Default gateway"
}

variable "ip_prefix" {
  type        = number
  description = "Subnet prefix length"
  default     = 24
}

variable "mac_address" {
  type        = string
  description = "MAC address to keep across rebuilds; empty lets Proxmox generate one"
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "VM name"
  default     = "Git-Dev-Runner"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VMID"
  default     = 504
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "GitLab CI runner for development projects, managed by Terraform"
}

variable "cores" {
  type        = number
  description = "CPU cores; two concurrent jobs"
  default     = 4
}

variable "memory" {
  type        = number
  description = "Memory in MB; two concurrent jobs, the heaviest being Rust builds"
  default     = 8192
}

variable "os_disk_size" {
  type        = string
  description = "OS disk size; can grow but never shrink"
  default     = "80G"
}

variable "bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "start_at_node_boot" {
  type        = bool
  description = "Start the VM when its Proxmox node boots"
  default     = true
}

variable "tags" {
  type        = string
  description = "Semicolon-separated Proxmox tags"
  default     = "terraform"
}
