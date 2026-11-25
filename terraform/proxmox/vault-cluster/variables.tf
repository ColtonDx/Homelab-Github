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

# Built by build-project.yaml from the vault_cluster inventory group: each host's terraform_defaults, its ansible_host as address, then its own terraform dict
variable "nodes" {
  description = "The cluster's members; template_id (a template's VMID) takes precedence over template_name; storage_pool, template_name, gateway and ip_prefix fall back to the project-wide values; protection (default true) is Proxmox's delete guard, turned off for the one member being rebuilt"
  type = list(object({
    name          = string
    vm_id         = number
    target_node   = string
    address       = string
    template_id   = optional(number)
    template_name = optional(string)
    storage_pool  = optional(string)
    gateway       = optional(string)
    ip_prefix     = optional(number)
    cores         = optional(number, 2)
    memory        = optional(number, 2048)
    os_disk_size  = optional(string, "32G")
    mac_address   = optional(string)
    protection    = optional(bool, true)
  }))

  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.name])) && length(var.nodes) == length(distinct([for n in var.nodes : n.vm_id]))
    error_message = "Every member needs a unique name and vm_id."
  }

  # Raft needs a majority, so an even count adds a member without adding a failure it can survive
  validation {
    condition     = length(var.nodes) % 2 == 1
    error_message = "Use an odd number of members (3 or 5)."
  }

  # Two members on one host would lose quorum together when that host goes down
  validation {
    condition     = length(var.nodes) == length(distinct([for n in var.nodes : n.target_node]))
    error_message = "Every member needs its own Proxmox host."
  }
}

variable "template_name" {
  type        = string
  description = "Cloud-init template to clone, for members that set neither template_id nor template_name"
  default     = null
}

variable "storage_pool" {
  type        = string
  description = "Storage for the OS and cloud-init disks, unless a member sets its own"
}

variable "gateway" {
  type        = string
  description = "Default gateway, unless a member sets its own"
}

variable "ip_prefix" {
  type        = number
  description = "Subnet prefix length, unless a member sets its own"
  default     = 24
}

variable "bridge" {
  type        = string
  description = "Network bridge"
  default     = "vmbr0"
}

variable "description" {
  type        = string
  description = "Proxmox description"
  default     = "Vault cluster member - Deployed by Terraform"
}
