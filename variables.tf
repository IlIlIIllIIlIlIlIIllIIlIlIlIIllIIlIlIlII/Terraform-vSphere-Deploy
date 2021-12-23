#Sets the name in vSphere and the name for the host
variable "vm_name" {
  type = string
  default = "SetAName"
}

variable "uniq_code"{
  type = string
  default = "52"
}

variable "vlan_name"{
  type = string
  default = "VM Network"
}

variable "ip_address"{
  type = string
  default = "192.168.50.241"
}

variable "net_mask"{
  type = string
  default = "24"
}
