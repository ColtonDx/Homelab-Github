# Where each member landed, to confirm one member per Proxmox host
output "node_placement" {
  description = "Member name to Proxmox host"
  value       = { for k, v in proxmox_vm_qemu.vault_node : k => v.target_node }
}

output "node_vmids" {
  description = "Member name to VMID"
  value       = { for k, v in proxmox_vm_qemu.vault_node : k => v.vmid }
}

output "dns_reservations" {
  description = "Name, address and MAC of each member, which build-project.yaml records in NetBox after an apply"
  value = [for k, v in proxmox_vm_qemu.vault_node : {
    name = k
    ip   = local.nodes[k].address
    mac  = v.network[0].macaddr
  }]
}
