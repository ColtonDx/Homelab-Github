# Builds the legacy K3s cluster's VMs on Proxmox, one per entry in the nodes variable; Talos is the current cluster, and this is kept so K3s can be rebuilt
# Normally run through ansible/playbooks/terraform/build-project.yaml, which then runs ansible/playbooks/k3s/initialize.yaml to build the cluster on them
# A direct run needs AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage, TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret, and site values in terraform.tfvars
# Adopting existing VMs: terraform import 'proxmox_vm_qemu.k3s_node["<name>"]' <proxmox_node>/qemu/<vmid>

terraform {
  # Garage stores the state; the key is the one the earlier K3s project used, so existing nodes carry over
  backend "s3" {
    bucket                      = "terraform"
    key                         = "k3s-nodes.tfstate"
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

# Every node is a server (control plane, worker and Longhorn storage); spread them across Proxmox hosts so one host cannot take etcd's quorum
resource "proxmox_vm_qemu" "k3s_node" {
  for_each = local.nodes

  name         = each.key
  vmid         = each.value.vmid
  description  = var.description
  target_nodes = [each.value.proxmox_node]
  tags         = "terraform;k3s"

  # Cloned once from the template; the template only matters at creation
  clone      = var.template_name
  full_clone = true

  # The PACT templates carry the guest agent, and configure-cluster.yaml keeps it running
  agent = 1

  os_type = "cloud-init"
  ciuser  = var.ci_user
  # null rather than an empty string, so the template's own key is kept when none is given
  sshkeys = trimspace(var.ssh_public_keys) != "" ? var.ssh_public_keys : null

  memory  = each.value.memory
  scsihw  = "virtio-scsi-pci"
  bios    = "seabios"
  boot    = "order=scsi0"
  balloon = 0

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
      ide3 {
        cloudinit {
          storage = coalesce(each.value.storage_pool, var.storage_pool)
        }
      }
    }

    scsi {
      # The OS disk
      scsi0 {
        disk {
          size    = each.value.os_disk_size
          storage = coalesce(each.value.storage_pool, var.storage_pool)
        }
      }

      # Longhorn's data disk; configure-cluster.yaml finds it as the unpartitioned disk, so its device name does not matter
      scsi1 {
        disk {
          size    = each.value.data_disk_size
          storage = coalesce(each.value.storage_pool, var.storage_pool)
        }
      }
    }
  }

  ipconfig0 = "ip=${each.value.address}/${var.ip_prefix},gw=${var.gateway}"

  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
  }

  lifecycle {
    # The template only matters at creation, and an imported VM has none recorded
    ignore_changes = [clone, full_clone]
  }
}
