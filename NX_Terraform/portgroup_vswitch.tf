# Deploy vSwitch and its associated port-group

resource "vsphere_host_virtual_switch" "pod_vswitches" {

  for_each = var.switch_data

  name = format("vSwitch_%s", replace(each.key, "X", var.pod))
  host_system_id      = data.vsphere_host.esxi_host.id
  mtu = 9000
  network_adapters = []
  active_nics = []
  standby_nics = []
}

resource "vsphere_host_port_group" "pod_portgroups" {

  for_each = var.switch_data

  name                = format("(2%02s%s) POD%s_NX1_NX2_%s", var.pod, each.value["index"], var.pod, each.value["index"])
  host_system_id      = data.vsphere_host.esxi_host.id
  virtual_switch_name = format("vSwitch_%s", replace(each.key, "X", var.pod))

  vlan_id = 4095
  allow_promiscuous = true
  allow_forged_transmits = true
  allow_mac_changes = true

  depends_on = [
    vsphere_host_virtual_switch.pod_vswitches
  ]
}


