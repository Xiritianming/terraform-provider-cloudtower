terraform {
  required_providers {
    cloudtower = {
      version = "~> 0.1.4"
      source  = "registry.terraform.io/smartx/cloudtower"
    }
  }
}

provider "cloudtower" {
  username          = var.tower_config["user"]
  user_source       = var.tower_config["source"]
  cloudtower_server = var.tower_config["server"]
}


resource "cloudtower_cluster" "sample_cluster" {
  ip       = var.cluster_config["ip"]
  username = var.cluster_config["user"]
  password = var.cluster_config["password"]
}

data "cloudtower_vlan" "vm_vlan" {
  name       = "default"
  type       = "VM"
  cluster_id = cloudtower_cluster.sample_cluster.id
}

data "cloudtower_host" "target_host" {
  management_ip_contains = "31.16"
  cluster_id             = cloudtower_cluster.sample_cluster.id
}

resource "cloudtower_vm" "tf_test" {
  name                = "tf-test-to-be-cloned-by-vm"
  description         = "managed by terraform"
  cluster_id          = cloudtower_cluster.sample_cluster.id
  host_id             = data.cloudtower_host.target_host.hosts[0].id
  vcpu                = 4
  memory              = 4 * 1024 * 1024 * 1024
  ha                  = false
  firmware            = "BIOS"
  status              = "STOPPED"
  force_status_change = true

  cd_rom {
    boot   = 2
    iso_id = ""
  }

  disk {
    boot = 1
    bus  = "VIRTIO"
    vm_volume {
      storage_policy = "REPLICA_2_THIN_PROVISION"
      name           = "d1"
      size           = 20 * 1024 * 1024 * 1024
    }
  }

  nic {
    vlan_id = data.cloudtower_vlan.vm_vlan.vlans[0].id
  }
}

resource "cloudtower_vm_template" "tf_test_template_clone_from_vm" {
  name  = "tf-test-template-by-cloned-from-vm"
  cloud_init_supported = false
  description = "first tf template"
  create_effect {
    clone_from_vm = cloudtower_vm.tf_test.id
  }
}