# Where each node landed, to confirm one node per Proxmox host
output "node_placement" {
  description = "Node name to Proxmox host"
  value       = { for k, v in proxmox_vm_qemu.talos_node : k => v.target_node }
}

output "node_vmids" {
  description = "Node name to VMID"
  value       = { for k, v in proxmox_vm_qemu.talos_node : k => v.vmid }
}

output "dns_reservations" {
  description = "Name, address and MAC of each node with an address, which build-project.yaml reserves in OPNsense Dnsmasq after an apply"
  value = [for k, v in proxmox_vm_qemu.talos_node : {
    name = k
    ip   = local.nodes[k].address
    mac  = v.network[0].macaddr
  } if local.nodes[k].address != null]
}
