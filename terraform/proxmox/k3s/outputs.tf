# Where each node landed, to confirm the nodes are spread across Proxmox hosts
output "node_placement" {
  description = "Node name to Proxmox host"
  value       = { for k, v in local.nodes : k => v.target_node }
}

output "node_addresses" {
  description = "Node name to IPv4 address"
  value       = { for k, v in local.nodes : k => v.address }
}
