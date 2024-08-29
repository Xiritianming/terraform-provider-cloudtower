variable "cloudtower_user" {
  type = string
}

variable "cloudtower_password" {
  type = string
}

variable "cloudtower_user_source" {
  type    = string
  default = "local"
}

variable "cloudtower_server" {
  type = string
}

variable "clusters" {
  type = list(string)
}

variable "hosts" {
  type     = list(string)
  default  = null
  nullable = true
}


variable "template_name" {
  type = string
}

variable "vm_name" {
  type = list(string)

}

variable "vm_ip" {
  type = list(string)
}

variable "vm_status" {
  type = string
}

variable "vm_cpu" {
  type = number
}

variable "vm_memory" {
  type = number
}

variable "vm_hostname" {
  type = list(string)
}

variable "vm_dns" {
  type = list(string)
}

variable "vm_password" {
  type = string
}

variable "vm_portgroup" {
  type = list(string)
}

variable "vm_network_type" {
  type        = string
  description = "`vm_networktype` must be `IPV4` or `IPV4_DHCP`."
  validation {
    condition     = contains(["IPV4", "IPV4_DHCP"], var.vm_network_type)
    error_message = "`vm_networktype` must be `IPV4` or `IPV4_DHCP`."
  }
}

variable "vm_network_gateway" {
  type = string
}

variable "vm_network_cidr" {
  type = number
}

variable "vm_extra_disks" {
  type = list(
    object({
      bus            = string
      storage_policy = string
      size           = number
    })
  )
}

variable "validation_vm_counts" {
  type    = bool
  default = true
  validation {
    condition     = var.hosts == null ? var.validation_vm_counts == true && length(var.vm_name) == length(var.vm_ip) && length(var.vm_name) == length(var.vm_hostname) : var.validation_vm_counts == true && length(var.vm_name) == length(var.vm_ip) && length(var.vm_name) == length(var.vm_hostname) && length(var.vm_name) == length(var.hosts)
    error_message = "`vm_ip`, `vm_name`, `vm_ip`, `hosts` must have the same length."
  }
}