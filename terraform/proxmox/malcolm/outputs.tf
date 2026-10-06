# Where Malcolm ended up, for the inventory and DNS
output "malcolm_address" {
  description = "Malcolm's static IPv4 address"
  value       = var.ip_address
}

output "malcolm_vmid" {
  description = "Malcolm's Proxmox VMID"
  value       = proxmox_vm_qemu.malcolm.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml reserves in OPNsense Dnsmasq after an apply; the management NIC only"
  value = [{
    name = proxmox_vm_qemu.malcolm.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.malcolm.network[0].macaddr
  }]
}
