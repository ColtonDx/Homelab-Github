# Where the server ended up, for the inventory and DNS
output "monitoring_address" {
  description = "The monitoring server's static IPv4 address"
  value       = var.ip_address
}

output "monitoring_vmid" {
  description = "The monitoring server's Proxmox VMID"
  value       = proxmox_vm_qemu.monitoring.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml records in NetBox after an apply"
  value = [{
    name = proxmox_vm_qemu.monitoring.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.monitoring.network[0].macaddr
  }]
}
