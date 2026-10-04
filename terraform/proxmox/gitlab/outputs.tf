# Where GitLab ended up, for the inventory and DNS
output "gitlab_address" {
  description = "GitLab's static IPv4 address"
  value       = var.ip_address
}

output "gitlab_vmid" {
  description = "GitLab's Proxmox VMID"
  value       = proxmox_vm_qemu.gitlab.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml reserves in OPNsense Dnsmasq after an apply"
  value = [{
    name = proxmox_vm_qemu.gitlab.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.gitlab.network[0].macaddr
  }]
}
