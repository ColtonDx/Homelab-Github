# Where Kasm ended up, for the inventory and DNS
output "kasm_address" {
  description = "Kasm's static IPv4 address"
  value       = var.ip_address
}

output "kasm_vmid" {
  description = "Kasm's Proxmox VMID"
  value       = proxmox_vm_qemu.kasm.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml reserves in OPNsense Dnsmasq after an apply"
  value = [{
    name = proxmox_vm_qemu.kasm.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.kasm.network[0].macaddr
  }]
}
