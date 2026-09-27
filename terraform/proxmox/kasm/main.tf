# Builds the Kasm VM on Proxmox from a cloud-init template; ansible/playbooks/deployment/app-kasm.yaml installs Kasm Workspaces on it afterwards
# Environment: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage; TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id, TF_VAR_proxmox_api_token_secret
# Site values go in terraform.tfvars (gitignored); terraform.tfvars.example lists them
# Adopting an existing VM instead of building one: terraform import proxmox_vm_qemu.kasm <target_node>/qemu/<vm_id>

terraform {
  # Garage stores the state; its endpoint and credentials come from the AWS_* environment variables
  backend "s3" {
    bucket                      = "terraform"
    key                         = "kasm.tfstate"
    region                      = "garage"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  # Same provider and version as the adhoc-vm module; 3.0.2 is required for Proxmox 9
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

# Kasm runs its own Docker engine and session containers, so it gets a dedicated VM
resource "proxmox_vm_qemu" "kasm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  description = var.description

  # Cloned once from the template; ignored afterwards, see lifecycle below
  clone      = var.template_name
  full_clone = true

  # Off by default, as on the existing VM; Kasm is not a core service
  start_at_node_boot = var.start_at_node_boot

  os_type    = "cloud-init"
  qemu_os    = "other"
  bios       = "seabios"
  boot       = "order=scsi0"
  scsihw     = "virtio-scsi-pci"
  memory     = var.memory
  balloon    = 0
  agent      = 0
  hotplug    = "network,disk,usb"
  tablet     = true
  kvm        = true
  protection = false

  cpu {
    cores   = var.cores
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
          size      = var.os_disk_size
          storage   = var.storage_pool
          replicate = false
        }
      }
    }
  }

  # A static address, so DNS and the reverse proxy always find Kasm in the same place
  ipconfig0 = "ip=${var.ip_address}/${var.ip_prefix},gw=${var.gateway}"
  ciupgrade = false

  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    macaddr = var.mac_address != "" ? var.mac_address : null
  }

  lifecycle {
    # Destroying Kasm takes its workspaces, users and persistent profiles with it, so Terraform must never do it
    prevent_destroy = true
    # The template only matters at creation, and an imported VM has none recorded
    ignore_changes = [clone, full_clone]
  }
}
