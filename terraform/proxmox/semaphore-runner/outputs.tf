# Where the VM ended up, for the inventory and DNS
output "semaphore_runner_address" {
  description = "The VM's IPv4 address"
  value       = var.ip_address
}

output "semaphore_runner_vmid" {
  description = "The VM's Proxmox VMID"
  value       = proxmox_vm_qemu.semaphore_runner.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml records in NetBox after an apply"
  value = [{
    name = proxmox_vm_qemu.semaphore_runner.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.semaphore_runner.network[0].macaddr
  }]
}
