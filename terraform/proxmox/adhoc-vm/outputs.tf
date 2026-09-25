# The last applied inputs, read back by ansible/tasks/adhoc_vm_build.yaml so blank fields on a re-run keep their current value
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
