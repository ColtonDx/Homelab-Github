# Where GitLab ended up, for the inventory and DNS
output "gitlab_address" {
  description = "GitLab's static IPv4 address"
  value       = var.ip_address
}

output "gitlab_vmid" {
  description = "GitLab's Proxmox VMID"
  value       = proxmox_vm_qemu.gitlab.vmid
}
