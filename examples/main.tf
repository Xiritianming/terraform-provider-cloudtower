terraform {
  required_providers {
    cloudtower = {
      version = "~> 0.1.0"
      source  = "registry.terraform.io/smartx/cloudtower"
    }
  }
}

provider "cloudtower" {
  username          = "yanzhen"
  user_source       = "LDAP"
  cloudtower_server = "terraform.dev-cloudtower.smartx.com"
}

resource "cloudtower_datacenter" "idc" {
  name = "IDC"
}

output "idc_datacenter" {
  value = cloudtower_datacenter.idc
}

resource "cloudtower_cluster" "df_1761" {
  ip            = "192.168.17.39"
  username      = "root"
  password      = "tower2022"
  datacenter_id = cloudtower_datacenter.idc.id
}

output "df_1761_cluster" {
  value = cloudtower_cluster.df_1761
}

resource "cloudtower_vm" "tf_test" {
  name                = "yanzhen-tf-test"
  description         = "managed by terraform"
  cluster_id          = cloudtower_cluster.df_1761.id
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
      size           = 1 * 1024 * 1024 * 1024
    }
  }

  cd_rom {
    boot = 2
  }

  nic {
    vlan_id = "ckzmsi7i25k2c0926bx3w5xwy"
  }
}

output "test_vm" {
  value = cloudtower_vm.tf_test
}