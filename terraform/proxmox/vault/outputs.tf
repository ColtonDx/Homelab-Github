# Where Vault ended up, for the inventory and DNS
output "vault_address" {
  description = "Vault's static IPv4 address"
  value       = var.ip_address
}

output "vault_vmid" {
  description = "Vault's Proxmox VMID"
  value       = proxmox_vm_qemu.vault.vmid
}
