terraform {
  required_providers {
    cloudtower = {
      version = "~> 0.1.9"
      source  = "registry.terraform.io/smartxworks/cloudtower"
    }
  }
}

locals {
  GB = 1024 * local.MB
  MB = 1024 * local.KB
  KB = 1024
}

provider "cloudtower" {
  username          = var.cloudtower_user
  password          = var.cloudtower_password
  user_source       = var.cloudtower_user_source
  cloudtower_server = var.cloudtower_server
}

data "cloudtower_cluster" "cluster" {
  name = "SMTX-TEST-51-74_76"
}

data "cloudtower_vlan" "vm_vlan" {
  name       = "default"
  type       = "VM"
  cluster_id = data.cloudtower_cluster.cluster.clusters[0].id
}

resource "cloudtower_vm" "foo" {
  name          = "foo"
  vcpu          = 4
  cpu_cores     = 1
  cpu_sockets   = 4
  memory        = 8 * local.GB
  ha            = true
  firmware      = "BIOS"
  status        = "STOPPED" # clone to vm template need vm's status is `STOPPED`
  guest_os_type = "LINUX"
  cluster_id    = data.cloudtower_cluster.cluster.clusters[0].id


  disk {
    boot = 1
    bus  = "VIRTIO"
    vm_volume {
      storage_policy = "REPLICA_2_THIN_PROVISION"
      name           = "foo-1"
      size           = 40 * local.GB
    }
  }
  cd_rom {
    boot = 2
  }

  nic {
    vlan_id = data.cloudtower_vlan.vm_vlan.vlans[0].id
  }
}

resource "cloudtower_content_library_vm_template" "foo-template-from-vm" {
  name                 = "foo-template-from-vm"
  cluster_id           = ["${data.cloudtower_cluster.cluster.clusters[0].id}"]
  cloud_init_supported = false
  src_vm_id            = cloudtower_vm.foo.id
}