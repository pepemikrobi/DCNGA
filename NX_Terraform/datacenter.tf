data "vsphere_datacenter" "datacenter" {
  name = "CSH"
}

data "vsphere_host" "esxi_host" {
  name          = var.esxi_hostname
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

