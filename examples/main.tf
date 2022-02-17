terraform {
  required_providers {
    cloudtower = {
      version = "~> 0.1.0"
      source  = "registry.terraform.io/smartx/cloudtower"
    }
  }
}

provider "cloudtower" {
  username          = "root"
  user_source       = "LOCAL"
  cloudtower_server = "terraform.dev-cloudtower.smartx.com"
}

data "cloudtower_datacenter" "idc" {
  name = "idc"
}

output "test" {
  value = data.cloudtower_datacenter.idc
}

resource "cloudtower_cluster" "c_1739" {
  ip            = "192.168.17.39"
  username      = "root"
  password      = "tower2022"
  datacenter_id = data.cloudtower_datacenter.idc.datacenters[0].id
}

data "cloudtower_vlan" "vm_vlan" {
  name = "default"
  type = "VM"
  cluster_id = cloudtower_cluster.c_1739.id
}

data "cloudtower_iso" "ubuntu" {
  name_contains = "ubuntu-18"
  cluster_id = cloudtower_cluster.c_1739.id
}

resource "cloudtower_vm" "tf_test" {
  name                = "yanzhen-tf-test"
  description         = "managed by terraform ~~"
  cluster_id          = cloudtower_cluster.c_1739.id
  vcpu                = 4
  memory              = 8 * 1024 * 1024 * 1024
  ha                  = true
  firmware            = "BIOS"
  status              = "RUNNING"
  force_status_change = true
  disk {
    boot = 1
    bus  = "VIRTIO"
    vm_volume {
      storage_policy = "REPLICA_2_THIN_PROVISION"
      name           = "v1"
      size           = 10 * 1024 * 1024 * 1024
    }
  }
  cd_rom {
    boot   = 2
    iso_id = data.cloudtower_iso.ubuntu.isos[0].id
  }
  nic {
    vlan_id = data.cloudtower_vlan.vm_vlan.vlans[0].id
  }
}

output "test_vm" {
  value = cloudtower_vm.tf_test
}
