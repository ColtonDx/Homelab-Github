# Where the VM ended up, for the inventory and DNS
output "dev_2_address" {
  description = "The VM's IPv4 address"
  value       = var.ip_address
}

output "dev_2_vmid" {
  description = "The VM's Proxmox VMID"
  value       = proxmox_vm_qemu.dev_2.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml records in NetBox after an apply"
  value = [{
    name = proxmox_vm_qemu.dev_2.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.dev_2.network[0].macaddr
  }]
}
