# Where the VM ended up, for the inventory and DNS
output "workstation_vm_address" {
  description = "The VM's IPv4 address"
  value       = proxmox_vm_qemu.workstation_vm.default_ipv4_address
}

output "workstation_vm_vmid" {
  description = "The VM's Proxmox VMID"
  value       = proxmox_vm_qemu.workstation_vm.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml records in NetBox after an apply"
  value = [{
    name = proxmox_vm_qemu.workstation_vm.name
    ip   = proxmox_vm_qemu.workstation_vm.default_ipv4_address
    mac  = proxmox_vm_qemu.workstation_vm.network[0].macaddr
  }]
}
