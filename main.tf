provider "vsphere" {
  user           = "Administrator@sphere.local"
  password       = "Passw0rd"
  vsphere_server = "192.168.50.20"

  allow_unverified_ssl = true
}

#-------------------------------------------------------------------------------
#                                     Constant Variables
#-------------------------------------------------------------------------------
variable "num_cpus"{
  type = number
  default = 1
}

variable "memory"{
  type = number
  default = 2048
}

#format this based on host name to use the correct dsc for the OS
variable "target_datastore"{
  type = string
  default =  "Disk 2"
}

#Sets the template the vm will be created from
variable "vm_template_name"{
  type = string
  default = "Server 2016"
}

#-------------------------------------------------------------------------------
#                                     Authentication Variables
#-------------------------------------------------------------------------------
/*
variable "login_credz"{
  type = string
  description = "AD user name:"
}

variable "login_password"{
  type = string
  description = "Password: "
}
*/
#-------------------------------------------------------------------------------
#                                     Random Password Generation
#-------------------------------------------------------------------------------
resource "random_password" "password" {
  length = 23
  special = true
  number = true
  upper = true
  lower = true
}
#-------------------------------------------------------------------------------
#                                     Vm Creation
#-------------------------------------------------------------------------------
  data "vsphere_datacenter" "dc" {
    name = "Home"
  }

  data "vsphere_datastore" "datastore" {
    name          = var.target_datastore
    datacenter_id = data.vsphere_datacenter.dc.id
  }

  data "vsphere_compute_cluster" "cluster" {
    name          = "Normal"
    datacenter_id = data.vsphere_datacenter.dc.id
  }

  data "vsphere_network" "network" {
    name          = var.vlan_name
    datacenter_id = data.vsphere_datacenter.dc.id
  }

  data "vsphere_virtual_machine" "template" {
    name          = var.vm_template_name
    datacenter_id = data.vsphere_datacenter.dc.id
  }

  resource "vsphere_virtual_machine" "vm" {

    #Generates a random password first
    depends_on = [random_password.password]

    name             = lower("${var.uniq_code}_${var.vm_name}")
    resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
    datastore_id     = data.vsphere_datastore.datastore.id

    num_cpus = var.num_cpus
    memory   = var.memory
    guest_id = data.vsphere_virtual_machine.template.guest_id
    firmware = "efi"

    scsi_type = data.vsphere_virtual_machine.template.scsi_type

    network_interface {
      network_id   = data.vsphere_network.network.id
      adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    }

    disk {
      label            = "disk0"
      size             = data.vsphere_virtual_machine.template.disks.0.size
      eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
      thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    }

    clone {
      template_uuid = data.vsphere_virtual_machine.template.id

      customize {
        windows_options {
          computer_name = var.vm_name
          admin_password = random_password.password.result
          auto_logon = true
          auto_logon_count = 3
        }

        network_interface {
          ipv4_address = var.ip_address
          ipv4_netmask = var.net_mask
        }

        ipv4_gateway = "192.168.1.1"
        dns_server_list = ["192.168.1.1"]
      }
    }

    #Adds ad group to local Administrators
    provisioner "remote-exec" {
      inline = ["powhershell.exe -Command Write-Host 'hello world'"]
      connection {
        host     = var.ip_address
        type     = "winrm"
        https    = false
        user     = "Administrator"
        password = random_password.password.result
        agent    = false
        insecure = true
        }
    }

}

#-------------------------------------------------------------------------------
#                                     Output
#-------------------------------------------------------------------------------

output "host_name"{
	#provider.variableName.requestedInfo
	value = var.vm_name
}

output "password"{
	#provider.variableName.requestedInfo
	value = random_password.password.result
}
