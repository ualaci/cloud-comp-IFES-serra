terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

locals {
  vms = {
    "alpine-node" = {
      cpus   = 1
      memory = "512 mib"
      image  = "./alpine318_generic"
    },
    "ubuntu-node" = {
      cpus   = 1
      memory = "1024 mib"
      image  = "./trusty-server-cloudimg-amd64-vagrant-disk1.box"
    }
  }
}

resource "virtualbox_vm" "cluster" {
  for_each = local.vms

  name   = each.key
  image  = each.value.image
  cpus   = each.value.cpus
  memory = each.value.memory

  network_adapter {
    type           = "bridged"
    host_interface = "Intel(R) Ethernet Connection (11) I219-LM"
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "VBoxManage controlvm ${each.key} poweroff; Start-Sleep -Seconds 5; VBoxManage modifyvm ${each.key} --usb off; VBoxManage sharedfolder add ${each.key} --name lubuntu_vm_shared_folder --hostpath 'D:\\Usuarios\\20261mpca0208\\Documents\\lubuntu_vm_shared_folder' --automount; VBoxManage startvm ${each.key} --type headless"
  }
}

output "vms_ips" {
  value = {
    for k, vm in virtualbox_vm.cluster : k => vm.network_adapter[0].ipv4_address
  }
}