terraform {
  required_providers {
    cloudtower = {
      version = "~> 0.1.7"
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

data "cloudtower_cluster" "query_clusters" {
  name_in = var.clusters
}

data "cloudtower_host" "query_hosts" {
  management_ip_in = var.hosts
}

data "cloudtower_content_library_vm_template" "query_template" {
  name = var.template_name
}

data "cloudtower_vlan" "query_vlans" {
  name_in = var.vm_portgroup
}

locals {
  cluster_name_map = {
    for cluster in data.cloudtower_cluster.query_clusters.clusters :
    cluster.name => {
      for k, v in cluster : k => v
    }
  }
  host_ip_map = {
    for host in data.cloudtower_host.query_hosts.hosts :
    host.management_ip => {
      for k, v in host : k => v
    }
  }
  vlan_name_map = { for n, vlans in {
    for vlan in data.cloudtower_vlan.query_vlans.vlans :
    vlan.name => vlan...
    } :
    n => {
      for vlan in vlans :
      vlan.cluster_id => {
        for k, v in vlan : k => v
      }
    }
  }
}

# output "cluster_name_map" {
#   value = local.vlan_name_map
# }

# output "host_ip_map" {
#   value = local.host_ip_map
# }

# output "vlan_name_map" {
#   value = local.vlan_name_map
# }

resource "cloudtower_vm" "vms_create_from_template" {
  count      = length(var.vm_ip)
  cluster_id = length(var.clusters) > 1 ? local.cluster_name_map[var.clusters[count.index]].id : data.cloudtower_cluster.query_clusters.clusters[0].id
  # cluster_id = data.cloudtower_cluster.query_clusters.clusters[0].id
  host_id = var.hosts == null ? null : local.host_ip_map[var.hosts[count.index]].id
  # host_id = data.cloudtower_host.query_hosts.hosts[0].id
  name   = var.vm_name[count.index]
  vcpu   = var.vm_cpu
  memory = var.vm_memory * local.GB
  status = var.vm_status
  create_effect {
    is_full_copy                        = false
    clone_from_content_library_template = data.cloudtower_content_library_vm_template.query_template.content_library_vm_templates[0].id
    cloud_init {
      hostname              = var.vm_hostname[count.index]
      nameservers           = var.vm_dns
      default_user_password = var.vm_password
      networks {
        type       = var.vm_network_type
        nic_index  = 0
        ip_address = var.vm_ip[count.index]
        netmask    = cidrnetmask("${var.vm_network_gateway}/${var.vm_network_cidr}")
        routes {
          gateway = var.vm_network_gateway
          netmask = "0.0.0.0"
          network = "0.0.0.0"
        }
      }
    }
  }
  dynamic "disk" {
    # original template's disks
    for_each = data.cloudtower_content_library_vm_template.query_template.content_library_vm_templates[0].vm_templates[0].disks
    content {
      boot = disk.value.boot
      bus  = disk.value.bus
      vm_volume {
        storage_policy = disk.value.storage_policy
        name           = "${var.vm_name[count.index]}-${disk.key + 1}"
        size           = disk.value.size
        origin_path    = disk.value.path
      }
    }
  }
  dynamic "disk" {
    # extra disk
    for_each = var.vm_extra_disks
    content {
      boot = length(data.cloudtower_content_library_vm_template.query_template.content_library_vm_templates[0].vm_templates[0].disks) + (disk.key + 1)
      bus  = disk.value.bus
      vm_volume {
        storage_policy = disk.value.storage_policy
        name           = "${var.vm_name[count.index]}-${length(data.cloudtower_content_library_vm_template.query_template.content_library_vm_templates[0].vm_templates[0].disks) + (disk.key + 1)}"
        size           = disk.value.size * local.GB
      }
    }
  }

  cd_rom {
    boot = length(data.cloudtower_content_library_vm_template.query_template.content_library_vm_templates[0].vm_templates[0].disks) + length(var.vm_extra_disks[count.index]) + 1
  }
  nic {
    vlan_id = length(var.vm_portgroup) > 1 ? local.vlan_name_map[var.vm_portgroup[count.index]][local.cluster_name_map[var.clusters[count.index]].id].id : data.cloudtower_vlan.query_vlans.vlans[0].id
  }
}