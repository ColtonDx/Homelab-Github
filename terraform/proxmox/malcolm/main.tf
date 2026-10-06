# Builds the Malcolm VM on Proxmox from a cloud-init template; ansible/playbooks/terraform/build-project.yaml applies this and then installs Malcolm with app-malcolm.yaml
# Normally run through ansible/playbooks/terraform/build-project.yaml, which fills variables from the inventory, NetBox and Vault as sources.yaml describes
# A direct run needs AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_ENDPOINT_URL_S3 for Garage, TF_VAR_proxmox_api_url, TF_VAR_proxmox_api_token_id and TF_VAR_proxmox_api_token_secret, and site values in terraform.tfvars
# The capture bridge must already exist on the node and receive the switch's mirror (SPAN) traffic; Terraform only attaches the NIC to it

terraform {
  # Garage stores the state; its endpoint and credentials come from the AWS_* environment variables
  backend "s3" {
    bucket                      = "terraform"
    key                         = "malcolm.tfstate"
    region                      = "garage"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  # Same provider and version as the other projects; 3.0.2 is required for Proxmox 9
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

# Malcolm runs OpenSearch, Arkime, Zeek and Suricata in Docker and captures from its second NIC, so it gets a dedicated VM
resource "proxmox_vm_qemu" "malcolm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.target_node
  description = var.description

  # Cloned once from the template; ignored afterwards, see lifecycle below
  clone      = var.template_name
  full_clone = true

  # On by default, so capture resumes after a node reboot
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

      # OpenSearch indices, PCAP and Zeek logs live here, mounted by app-malcolm.yaml, so they can grow apart from the OS
      scsi1 {
        disk {
          size      = var.data_disk_size
          storage   = var.data_storage_pool != "" ? var.data_storage_pool : var.storage_pool
          replicate = false
        }
      }
    }
  }

  # A static address, so DNS and the reverse proxy always find Malcolm in the same place; the capture NIC gets none
  ipconfig0 = "ip=${var.ip_address}/${var.ip_prefix},gw=${var.gateway}"
  ciupgrade = false

  # Management: the web UI, SSH and log forwarders
  network {
    id      = 0
    model   = "virtio"
    bridge  = var.bridge
    macaddr = var.mac_address != "" ? var.mac_address : null
  }

  # Capture: mirrored traffic only, no address and no firewall, so nothing on the VM answers on it
  network {
    id       = 1
    model    = "virtio"
    bridge   = var.capture_bridge
    firewall = false
  }

  lifecycle {
    # Destroying Malcolm takes its indexed traffic and stored PCAP with it, so Terraform must never do it
    prevent_destroy = true
    # The template only matters at creation, and an imported VM has none recorded
    ignore_changes = [clone, full_clone]
  }
}
