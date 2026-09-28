# Where each node landed, to confirm one node per Proxmox host
output "node_placement" {
  description = "Node name to Proxmox host"
  value       = { for k, v in proxmox_vm_qemu.talos_node : k => v.target_node }
}

output "node_vmids" {
  description = "Node name to VMID"
  value       = { for k, v in proxmox_vm_qemu.talos_node : k => v.vmid }
}
