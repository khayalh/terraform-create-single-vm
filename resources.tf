# resource "azurerm_resource_group" "azure_network" {
#   location = "westeurope"
#   name = "terraformrg"
# }
# resource "azurerm_virtual_network" "blue_vnet" {
#   address_space = ["10.0.0.0/16"]
#   location = "westeurope"
#   name = "bluevnet"
#   resource_group_name = "${azurerm_resource_group.azure_network.name}"
#   dns_servers = ["10.0.0.4","10.0.0.5"]
#   subnet {
#     name = "subnet1"
#     address_prefix = "10.0.1.0/24"
#   }
#   subnet {
#     name = "subnet2"
#     address_prefix = "10.0.2.0/24"
#   }
# }
data "vsphere_datacenter" "dc" {
  name = "${var.datacenter}"
}

data "vsphere_datastore" "datastore" {
  name          = "${var.datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.pool}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name  = "${var.vm_name}"

  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 3
  memory   = 4096
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

        customize {
            linux_options {
                 host_name = "${var.host_name}"
                 domain = "${var.domain_name}"
                 time_zone = "${var.vm_time_zone}"
           }

        network_interface {
          ipv4_address = "${var.count_ip}"
          ipv4_netmask = "24"
       }

        dns_server_list = "${var.dns_server}" 
        ipv4_gateway = "${var.gateway}"
     }
   }
}