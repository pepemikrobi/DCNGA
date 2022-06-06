terraform {
  required_version = ">= 0.13"
  required_providers {
    esxi = {
      source = "josenk/esxi"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
  }
}

