vcsa_hostname = "vcenter.sdn.lab"
vcsa_username = "podX-admin@hector.lan"
esxi_hostname = ""
esxi_datastore = ""

pod = X

switch_data = {
  NX1 = {
    name = "podX-nx1"
    index = 1
    serial_port = 3XX1
    eth1 = 11
    eth2 = 12
    eth3 = 13
  }
  NX2 = {
    name = "podX-nx2"
    index = 2
    serial_port = 3XX2
    eth1 = 21
    eth2 = 22
    eth3 = 23
  }
}

