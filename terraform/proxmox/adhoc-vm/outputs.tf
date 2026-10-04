# The last applied inputs, read back by ansible/playbooks/terraform-adhoc-vm/tasks/setup.yaml so blank fields on a re-run keep their current value
output "vm_name" {
  value = var.vm_name
}

output "template_name" {
  value = var.template_name
}

output "target_node" {
  value = var.target_node
}

output "storage_pool" {
  value = var.storage_pool
}

output "cores" {
  value = var.cores
}

output "vcpus" {
  value = var.vcpus
}

output "memory" {
  value = var.memory
}

output "osdisk_size" {
  value = var.osdisk_size
}

output "data_disk_size" {
  value = var.data_disk_size
}

output "data_storage_pool" {
  value = var.data_storage_pool
}

output "ipconfig0" {
  value = var.ipconfig0
}

output "tags" {
  value = var.tags
}

output "dns_reservations" {
  description = "Name, address and MAC of the VM when it has a static address, which build-vm.yaml reserves in OPNsense Dnsmasq; empty for DHCP"
  value = can(regex("ip=([0-9.]+)/", var.ipconfig0)) ? [{
    name = proxmox_vm_qemu.clone.name
    ip   = regex("ip=([0-9.]+)/", var.ipconfig0)[0]
    mac  = proxmox_vm_qemu.clone.network[0].macaddr
  }] : []
}
