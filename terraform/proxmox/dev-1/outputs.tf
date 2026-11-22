# Where the VM ended up, for the inventory and DNS
output "dev_1_address" {
  description = "The VM's IPv4 address"
  value       = var.ip_address
}

output "dev_1_vmid" {
  description = "The VM's Proxmox VMID"
  value       = proxmox_vm_qemu.dev_1.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml records in NetBox after an apply"
  value = [{
    name = proxmox_vm_qemu.dev_1.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.dev_1.network[0].macaddr
  }]
}
