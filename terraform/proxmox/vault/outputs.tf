# Where Vault ended up, for the inventory and DNS
output "vault_address" {
  description = "Vault's static IPv4 address"
  value       = var.ip_address
}

output "vault_vmid" {
  description = "Vault's Proxmox VMID"
  value       = proxmox_vm_qemu.vault.vmid
}

output "dns_reservations" {
  description = "Name, address and MAC of each VM, which build-project.yaml reserves in OPNsense Dnsmasq after an apply"
  value = [{
    name = proxmox_vm_qemu.vault.name
    ip   = var.ip_address
    mac  = proxmox_vm_qemu.vault.network[0].macaddr
  }]
}
