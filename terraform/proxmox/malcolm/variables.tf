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
  description = "Proxmox node the VM runs on; it must have the capture bridge"
}

variable "template_name" {
  type        = string
  description = "Cloud-init template to clone when building the VM from scratch"
}

variable "storage_pool" {
  type        = string
  description = "Storage for the OS and cloud-init disks"
}

variable "data_storage_pool" {
  type        = string
  description = "Storage for the data disk; empty uses storage_pool"
  default     = ""
}

variable "ip_address" {
  type        = string
  description = "Static IPv4 address of the management NIC, without the prefix"
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
  description = "Management NIC MAC address to keep when adopting an existing VM; empty lets Proxmox generate one"
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "VM name"
  default     = "malcolm"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VMID"
  default     = 153
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "Deployed by Terraform!"
}

variable "cores" {
  type        = number
  description = "CPU cores; Zeek, Suricata and OpenSearch each want several"
  default     = 8
}

variable "memory" {
  type        = number
  description = "Memory in MB; OpenSearch takes a quarter of it, so 16384 is a practical floor"
  default     = 24576
}

variable "os_disk_size" {
  type        = string
  description = "OS disk size, which holds Docker's images; can grow but never shrink"
  default     = "64G"
}

variable "data_disk_size" {
  type        = string
  description = "Data disk size for OpenSearch, PCAP and logs; can grow but never shrink"
  default     = "500G"
}

variable "bridge" {
  type        = string
  description = "Management network bridge"
  default     = "vmbr0"
}

variable "capture_bridge" {
  type        = string
  description = "Bridge that receives the switch's mirror (SPAN) traffic, for the capture NIC"
  default     = "vmbr1"
}

variable "start_at_node_boot" {
  type        = bool
  description = "Start the VM when its Proxmox node boots"
  default     = true
}
