terraform {
  # Endpoint and state key are supplied at init by ansible/tasks/adhoc_vm_setup.yaml, so nothing site-specific lives here
  backend "s3" {
    bucket                      = "terraform"
    region                      = "garage"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  # 3.0.2 is required for Proxmox 9 support
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = false
}

locals {
  data_storage_pool = var.data_storage_pool != "" ? var.data_storage_pool : var.storage_pool
}

# One VM per state file, keyed on the VMID at init
resource "proxmox_vm_qemu" "clone" {
  name        = var.vm_name
  description = "Deployed by Terraform"
  target_node = var.target_node
  vmid        = var.vm_id
  clone       = var.template_name
  full_clone  = true
  tags        = var.tags

  os_type = "cloud-init"
  memory  = var.memory
  scsihw  = var.scsihw
  bios    = var.bios
  boot    = "order=scsi0"
  balloon = 0

  cpu {
    cores   = var.cores
    sockets = var.vcpus
    type    = "host"
  }

  serial {
    id   = 0
    type = "socket"
  }

  disks {
    ide {
      ide3 {
        cloudinit {
          storage = var.storage_pool
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size    = var.osdisk_size
          storage = var.storage_pool
        }
      }

      dynamic "scsi1" {
        for_each = var.data_disk_size != "" ? [1] : []
        content {
          disk {
            size    = var.data_disk_size
            storage = local.data_storage_pool
          }
        }
      }
    }
  }

  ipconfig0 = var.ipconfig0

  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
  }

  # The template only matters at creation, so a re-run with a different one must not rebuild the VM
  lifecycle {
    ignore_changes = [clone, full_clone]
  }
}
