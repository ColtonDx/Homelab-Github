# Builds the Talos cluster's VMs on Proxmox, one per entry in talos_cluster.nodes; each boots the Talos ISO and waits in maintenance mode for its config
# Normally run through ansible/playbooks/terraform/build-project.yaml, which then runs ansible/playbooks/talos/init-cluster.yaml to configure and bootstrap the cluster
# A direct run needs AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage, TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret, and site values in terraform.tfvars
# Adopting existing VMs: terraform import 'proxmox_vm_qemu.talos_node["<name>"]' <target_node>/qemu/<vm_id>

terraform {
  # Garage stores the state; its endpoint and credentials come from the AWS_* environment variables
  backend "s3" {
    bucket                      = "terraform"
    key                         = "talos-nodes.tfstate"
    region                      = "garage"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  # Same provider and version as the other Proxmox projects; 3.0.2 is required for Proxmox 9
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc06"
    }
  }
}

# Credentials come from TF_VAR_* environment variables, so they never appear in files
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = false
}

locals {
  nodes = { for n in var.nodes : n.name => n }
}

# Each node names its own Proxmox host, so the inventory can keep one per host and a host failure never costs etcd its quorum
resource "proxmox_vm_qemu" "talos_node" {
  for_each = local.nodes

  name        = each.key
  vmid        = each.value.vm_id
  target_node = each.value.target_node
  description = var.description
  tags        = "terraform;talos"

  # A cluster node must come back on its own after a host reboot
  start_at_node_boot = true

  # Talos has no cloud-init, users or SSH; its address and everything else come from the machine config
  os_type = "other"
  qemu_os = "l26"
  bios    = "seabios"
  scsihw  = "virtio-scsi-pci"
  memory  = each.value.memory
  balloon = 0

  # qemu-guest-agent is a Talos system extension, so only enable it when the install image carries it
  agent = var.qemu_agent ? 1 : 0

  # Disk first, ISO as fallback, so an installed node boots Talos from disk rather than back into maintenance mode
  boot = "order=scsi0;ide2"

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  serial {
    id   = 0
    type = "socket"
  }

  disks {
    ide {
      ide2 {
        cdrom {
          iso = var.talos_iso
        }
      }
    }

    scsi {
      # The system disk Talos installs itself onto
      scsi0 {
        disk {
          size      = each.value.os_disk_size
          storage   = coalesce(each.value.storage_pool, var.storage_pool)
          replicate = false
        }
      }

      # Longhorn's data disk; the machine config finds it by size, so its device name does not matter
      scsi1 {
        disk {
          size      = each.value.data_disk_size
          storage   = coalesce(each.value.storage_pool, var.storage_pool)
          replicate = false
        }
      }
    }
  }

  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    macaddr = each.value.mac_address
  }
}
