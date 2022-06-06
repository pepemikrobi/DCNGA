provider "vsphere" {
  user           = var.vcsa_username
  password       = var.vcsa_password
  vsphere_server = var.vcsa_hostname

  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "CSH"
}

data "vsphere_resource_pool" "pool" {
  name          = "ADVRSBC_pods"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "esxi_host" {
  name          = var.esxi_hostname
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = "ESX1_0,5T_NVME"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "1733_template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "(ALL) CORE_SW"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


resource "vsphere_virtual_machine" "rt" {
  name                       = "POD0_RT6"
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.esxi_host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  #datacenter_id              = data.vsphere_datacenter.dc.id
  datacenter_id              = data.vsphere_datacenter.datacenter.id

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  /*ovf_deploy {
    local_ovf_path       = "/home/rslaski/csr1000v-universalk9.17.03.03.ova"
    disk_provisioning    = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
      "ESX-port-1" = data.vsphere_network.network.id
      "ESX-port-2" = data.vsphere_network.network.id
    }
  }*/

  vapp {
    properties = {
      "hostname" = "POD0_RT99"
    }
  }

}

