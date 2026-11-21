# Where the runner ended up, for the inventory and DNS
output "runner_address" {
  description = "The runner's static IPv4 address"
  value       = var.ip_address
}

output "runner_vmid" {
  description = "The runner's Proxmox VMID"
  value       = proxmox_vm_qemu.gitlab_runner.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml reserves in OPNsense Dnsmasq after an apply"
  value = [{
    name = proxmox_vm_qemu.gitlab_runner.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.gitlab_runner.network[0].macaddr
  }]
}
