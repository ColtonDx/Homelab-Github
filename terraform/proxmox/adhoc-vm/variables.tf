variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API URL, e.g. https://pve.example.com:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID, e.g. terraform@pve!adhoc"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret"
  sensitive   = true
}

variable "target_node" {
  type        = string
  description = "Proxmox node the VM is created on"
}

variable "storage_pool" {
  type        = string
  description = "Storage pool for the OS and cloud-init disks"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VMID; also keys the state file"
}

variable "vm_name" {
  type        = string
  description = "VM name"
}

variable "template_name" {
  type        = string
  description = "Name of the Proxmox template to clone"
}

variable "cores" {
  type        = number
  description = "CPU cores per socket"
  default     = 2
}

variable "vcpus" {
  type        = number
  description = "CPU sockets; the VM gets cores x vcpus CPUs in total"
  default     = 1
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 512
}

variable "osdisk_size" {
  type        = string
  description = "OS disk size, e.g. 32G; can grow on a re-run but never shrink"
  default     = "32G"
}

variable "data_disk_size" {
  type        = string
  description = "Optional data disk size, e.g. 100G; empty attaches no data disk"
  default     = ""
}

variable "data_storage_pool" {
  type        = string
  description = "Optional storage pool for the data disk; empty uses storage_pool"
  default     = ""
}

variable "ipconfig0" {
  type        = string
  description = "Cloud-init network config, e.g. ip=dhcp or ip=192.0.2.10/24,gw=192.0.2.1"
  default     = "ip=dhcp"
}

variable "tags" {
  type        = string
  description = "Semicolon-separated Proxmox tags"
  default     = "terraform"
}

variable "bridge" {
  type        = string
  description = "Network bridge for the VM's NIC"
  default     = "vmbr0"
}

variable "scsihw" {
  type        = string
  description = "SCSI controller type"
  default     = "virtio-scsi-pci"
}

variable "bios" {
  type        = string
  description = "BIOS type"
  default     = "seabios"
}
