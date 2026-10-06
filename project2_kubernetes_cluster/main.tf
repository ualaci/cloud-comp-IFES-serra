terraform {
  required_providers {
    vagrant = {
      source  = "bmatcuk/vagrant"
      version = "~> 4.1.0"
    }
  }
}

provider "vagrant" {}

resource "vagrant_vm" "k8s_cluster" {
  get_ports = false
}
