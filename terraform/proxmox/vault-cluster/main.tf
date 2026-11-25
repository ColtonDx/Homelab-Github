# Builds the VMs for a three-node HashiCorp Vault cluster (integrated Raft storage) on Proxmox, one per node, from a cloud-init template
# Normally run through ansible/playbooks/terraform/build-project.yaml, which fills the node list from the vault_cluster inventory group as sources.yaml describes
# A direct run needs AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage, TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret, and site values in terraform.tfvars
# Only the VMs: Vault itself is installed and joined into a cluster by a separate playbook, so a plain apply leaves empty Debian hosts

terraform {
  # optional() attributes in the node list need Terraform 1.3 or later
  required_version = ">= 1.3.0"

  # Garage stores the state; its endpoint and credentials come from the AWS_* environment variables
  backend "s3" {
    bucket                      = "terraform"
    key                         = "vault-cluster.tfstate"
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

# One VM per Proxmox host, so losing a host costs the cluster one member and never its quorum (two of three)
resource "proxmox_vm_qemu" "vault_node" {
  for_each = local.nodes

  name        = each.key
  vmid        = each.value.vm_id
  target_node = each.value.target_node
  description = var.description
  tags        = "terraform;vault"

  # A template on local storage can only be cloned on its own host, so a node can name its template by VMID; otherwise by name
  clone      = each.value.template_id == null ? coalesce(each.value.template_name, var.template_name) : null
  clone_id   = each.value.template_id
  full_clone = true

  # Every other service reads its secrets from Vault, so each member must come back on its own after a host reboot
  start_at_node_boot = true

  # Proxmox's own defaults (any order, default delay and timeout); the provider always reads this block back, so leaving it out shows a change on every plan
  startup_shutdown {}

  os_type = "cloud-init"
  qemu_os = "other"
  bios    = "seabios"
  boot    = "order=scsi0"
  scsihw  = "virtio-scsi-pci"
  memory  = each.value.memory
  balloon = 0
  agent   = 1
  hotplug = "network,disk,usb"
  tablet  = true
  kvm     = true

  # Proxmox refuses to delete a protected member, even from its own UI; rebuild one member at a time by turning it off for that member only
  protection = each.value.protection

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
    numa    = false
  }

  # Console over the serial port, which cloud images expect
  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  # Raft keeps a full copy of the data on every member, so storage stays on each host rather than shared, and is not replicated by Proxmox
  disks {
    ide {
      ide3 {
        cloudinit {
          storage = coalesce(each.value.storage_pool, var.storage_pool)
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size      = each.value.os_disk_size
          storage   = coalesce(each.value.storage_pool, var.storage_pool)
          replicate = false
        }
      }
    }
  }

  # A static address per member, which the cluster's peer list and clients' DNS rely on
  ipconfig0 = "ip=${each.value.address}/${coalesce(each.value.ip_prefix, var.ip_prefix)},gw=${coalesce(each.value.gateway, var.gateway)}"
  ciupgrade = false

  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    macaddr = each.value.mac_address
  }

  # Never reboot a member to apply a change; a restarted member comes back sealed
  automatic_reboot = false

  lifecycle {
    # The template only matters at creation
    ignore_changes = [clone, clone_id, full_clone]
  }
}
