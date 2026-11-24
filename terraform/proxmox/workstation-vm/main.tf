# Records a general-purpose workstation VM as Terraform, matching the live VM, so it can be rebuilt or brought under Terraform later; not applied to the live VM today
# Normally run through ansible/playbooks/terraform/build-project.yaml, which fills variables from the inventory, NetBox and Vault as sources.yaml describes
# A direct run needs AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage, TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret, and site values in terraform.tfvars
# Bringing it in means importing the live VM into this state first (terraform import); a plain apply would try to create a second VM

terraform {
  # Garage stores the state; its endpoint and credentials come from the AWS_* environment variables
  backend "s3" {
    bucket                      = "terraform"
    key                         = "workstation-vm.tfstate"
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

# Settings below mirror the live VM
resource "proxmox_vm_qemu" "workstation_vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  description = var.description
  tags        = var.tags

  # Proxmox's own defaults (any order, default delay and timeout); the provider always reads this block back, so leaving it out shows a change on every plan
  startup_shutdown {}

  # Cloned once from the template; ignored afterwards, see lifecycle below
  clone      = var.template_name
  full_clone = true

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

  # The live VM takes its address from DHCP
  ipconfig0 = "ip=dhcp"
  ciupgrade = false

  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    macaddr = var.mac_address != "" ? var.mac_address : null
  }

  lifecycle {
    # The template only matters at creation
    ignore_changes = [clone, full_clone]
  }
}
