
resource "vsphere_host_port_group" "pod_portgroups" {

  for_each = var.switch_data

  name                = format("(2%02s%s) POD%s_NX1_NX2_%s", var.pod, each.value["index"], var.pod, each.value["index"])
  host_system_id      = data.vsphere_host.esxi_host.id
  virtual_switch_name = "vSwitch0"

  vlan_id = format("2%02s%s", var.pod, each.value["index"])

  allow_promiscuous = true
  allow_forged_transmits = true
  allow_mac_changes = true

}



