variable "vcsa_hostname" {
}

variable "esxi_hostname" {
}

variable "vcsa_username" {
}

variable "vcsa_password" {
}

variable "pod" {
}

variable "switch_data" {
  type = map(object({
    name = string
    index = number
    serial_port = number
    eth1 = number
    eth2 = number
    eth3 = number
  }))
}

