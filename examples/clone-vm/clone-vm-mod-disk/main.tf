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


# original vm
resource "cloudtower_vm" "foo" {
  name          = "foo"
  vcpu          = 4
  cpu_cores     = 1
  cpu_sockets   = 4
  memory        = 8 * local.GB
  ha            = true
  firmware      = "BIOS"
  status        = "RUNNING"
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


# clone vm and modify disks
resource "cloudtower_vm" "foo-clone-3-modify-disks" {
  name       = "foo-clone-3-modify-disks"
  status     = "RUNNING"  # defalut is `STOPPED`
  cluster_id = data.cloudtower_cluster.cluster.clusters[0].id
  create_effect {
    is_full_copy  = false
    clone_from_vm = cloudtower_vm.foo.id
  }

  disk {
    # only bus and name can be modified
    boot = 1
    bus  = "SCSI"
    vm_volume {
      name           = "foo-clone-3-modify-disks-1"
      storage_policy = cloudtower_vm.foo.disk[0].vm_volume[0].storage_policy
      size           = cloudtower_vm.foo.disk[0].vm_volume[0].size
    }
  }
  disk {
    boot = 2
    bus  = "VIRTIO"
    vm_volume {
      storage_policy = "REPLICA_3_THIN_PROVISION"
      name           = "foo-clone-3-modify-disks-3"
      size           = 80 * local.GB
    }
  }
  cd_rom {
    boot = 3
  }
}