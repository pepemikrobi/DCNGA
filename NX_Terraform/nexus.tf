# Deploy Cisco Nexus 9300v virtual machine and add serial port using provisioner

data "vsphere_resource_pool" "pool" {
  name          = format("pod%s_dcnga", var.pod)
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.esxi_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = format("pod%s_n9300v_scsi_thin", var.pod)
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "net_mgmt" {
  name          = format("(11%02s) RSL_DCLAB_1%02s", var.pod, var.pod)
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "net_eth1" {
  name          = "${vsphere_host_port_group.pod_portgroups["PODX_N1"].name}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "net_eth2" {
  name                = "${vsphere_host_port_group.pod_portgroups["PODX_N2"].name}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


resource "vsphere_virtual_machine" "nexus" {

  for_each = var.switch_data

  name                       = each.value["name"]
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  datastore_id               = data.vsphere_datastore.datastore.id
  host_system_id             = data.vsphere_host.esxi_host.id
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
  num_cpus                   = 4
  memory                     = 8192
  firmware                   = "efi"
  guest_id                   = "otherGuest64"
  boot_delay                 = 2000
  
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
  }

  disk {
    label            = "disk0"
    size             = 10
    thin_provisioned = true
  }

  extra_config = {
    "efi.serialconsole.enabled" = "TRUE"
  }

  # mgmt0
  network_interface {
    network_id   = data.vsphere_network.net_mgmt.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    use_static_mac = true
    mac_address  = format("02:ca:fe:00:%02s:%02s", var.pod, each.value["eth1"])
  }

  # Eth1/1
  network_interface {
    network_id   = data.vsphere_network.net_eth1.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    use_static_mac = true
    mac_address  = format("02:ca:fe:00:%02s:%02s", var.pod, each.value["eth2"])
  }

  # Eth1/2
  network_interface {
    network_id   = data.vsphere_network.net_eth2.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
    use_static_mac = true
    mac_address  = format("02:ca:fe:00:%02s:%02s", var.pod, each.value["eth3"])
  }

}

resource "null_resource" "PowerShellScriptRunFirstTimeOnly" {
    for_each = var.switch_data

    triggers = {
      trigger = "${vsphere_virtual_machine.nexus[each.key].uuid}"
    }
    provisioner "local-exec" {

        #credits
        #http://access-console-port-virtual-machine.blogspot.com/2013/07/add-serial-port-to-vm-through-gui-or.html
        #https://kevsoft.net/2019/04/26/multi-line-powershell-in-terraform.html
        #https://markgossa.blogspot.com/2019/04/run-powershell-from-terraform.html?m=1
        command = <<EOPS

          Function New-SerialPort {
             Param(
               [string]$vmName,
               [string]$prt
             )
            $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
            $dev.operation = "add"
            $dev.device = New-Object VMware.Vim.VirtualSerialPort
            $dev.device.key = -1
            $dev.device.backing = New-Object VMware.Vim.VirtualSerialPortURIBackingInfo
            $dev.device.backing.direction = "server"
            $dev.device.backing.serviceURI = "telnet://:$prt"
            $dev.device.connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
            $dev.device.connectable.connected = $true
            $dev.device.connectable.StartConnected = $true
            $dev.device.yieldOnPoll = $true

            $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
            $spec.DeviceChange += $dev

            $vm = Get-VM -Name $vmName
            Stop-VM $VM -Confirm:$False
            $vm.ExtensionData.ReconfigVM($spec)
            Start-VM $VM -Confirm:$False
          }

          Connect-VIServer -Server ${var.vcsa_hostname} -User ${var.vcsa_username} -Password ${var.vcsa_password}
          New-SerialPort ${each.value["name"]} ${each.value["serial_port"]}
          Disconnect-VIServer -Confirm:$false
        EOPS
        interpreter = ["pwsh", "-Command"]
   }
}


