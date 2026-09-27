# Where Kasm ended up, for the inventory and DNS
output "kasm_address" {
  description = "Kasm's static IPv4 address"
  value       = var.ip_address
}

output "kasm_vmid" {
  description = "Kasm's Proxmox VMID"
  value       = proxmox_vm_qemu.kasm.vmid
}
