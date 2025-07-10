locals {
  // The name of the masters' ipconfiguration is hardcoded to "pipconfig". It needs to match cluster-api
  // https://github.com/openshift/cluster-api-provider-azure/blob/master/pkg/cloud/azure/services/networkinterfaces/networkinterfaces.go#L131
  ip_v4_configuration_name = "pipConfig"
  // TODO: Azure machine provider probably needs to look for pipConfig-v6 as well (or a different name like pipConfig-secondary)
  ip_v6_configuration_name = "pipConfig-v6"
}

resource "azurerm_network_interface" "master" {
  count = var.instance_count

  name                = "vmuataaccocpm0${count.index + 1}-nic"
  location            = var.region
  resource_group_name = var.resource_group_name

  dynamic "ip_configuration" {
    for_each = [for ip in [
      {
        // LIMITATION: azure does not allow an ipv6 address to be primary today
        primary : var.use_ipv4,
        name : local.ip_v4_configuration_name,
        ip_address_version : "IPv4",
        include : var.use_ipv4 || var.use_ipv6
      },
      {
        primary : ! var.use_ipv4,
        name : local.ip_v6_configuration_name,
        ip_address_version : "IPv6",
        include : var.use_ipv6
      },
      ] : {
      primary : ip.primary
      name : ip.name
      ip_address_version : ip.ip_address_version
      include : ip.include
      } if ip.include
    ]
    content {
      primary                       = ip_configuration.value.primary
      name                          = ip_configuration.value.name
      subnet_id                     = var.subnet_id
      private_ip_address_version    = ip_configuration.value.ip_address_version
      private_ip_address_allocation = "Dynamic"
    }
  }
  tags = {
    environment = var.environment
    project     = var.project
    purpose     = "master nic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "master_v4" {
  // This is required because terraform cannot calculate counts during plan phase completely and therefore the `vnet/public-lb.tf`
  // conditional need to be recreated. See https://github.com/hashicorp/terraform/issues/12570
  count = (! var.private || ! var.outbound_udr) ? var.instance_count : 0

  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  backend_address_pool_id = var.elb_backend_pool_v4_id
  ip_configuration_name   = local.ip_v4_configuration_name
}

resource "azurerm_network_interface_backend_address_pool_association" "master_v6" {
  // This is required because terraform cannot calculate counts during plan phase completely and therefore the `vnet/public-lb.tf`
  // conditional need to be recreated. See https://github.com/hashicorp/terraform/issues/12570
  count = var.use_ipv6 && (! var.private || ! var.outbound_udr) ? var.instance_count : 0

  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  backend_address_pool_id = var.elb_backend_pool_v6_id
  ip_configuration_name   = local.ip_v6_configuration_name
}

resource "azurerm_network_interface_backend_address_pool_association" "master_internal_v4" {
  count = var.use_ipv4 ? var.instance_count : 0

  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  backend_address_pool_id = var.ilb_backend_pool_v4_id
  ip_configuration_name   = local.ip_v4_configuration_name
}

resource "azurerm_network_interface_backend_address_pool_association" "master_internal_v6" {
  count = var.use_ipv6 ? var.instance_count : 0

  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  backend_address_pool_id = var.ilb_backend_pool_v6_id
  ip_configuration_name   = local.ip_v6_configuration_name
}

resource "azurerm_linux_virtual_machine" "master" {
  count = var.instance_count

  name                  = "vmuataaccocpm0${count.index+1}"
  location              = var.region
  zone                  = length(var.availability_zones) > 1 ? var.availability_zones[count.index] : var.availability_zones[0]
  resource_group_name   = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.master.*.id, count.index)]
  size                  = var.vm_size
  admin_username        = "core"
  # The password is normally applied by WALA (the Azure agent), but this
  # isn't installed in RHCOS. As a result, this password is never set. It is
  # included here because it is required by the Azure ARM API.
  admin_password                  = "NotActuallyApplied!"
  disable_password_authentication = false

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity]
  }

  os_disk {
    name                 = "vmuataaccocpm0${count.index + 1}_OSDisk" # os disk name needs to match cluster-api convention
    caching              = "ReadOnly"
    storage_account_type = var.os_volume_type
    disk_size_gb         = var.os_volume_size
  }

  source_image_id = var.vm_image

  //we don't provide a ssh key, because it is set with ignition. 
  //it is required to provide at least 1 auth method to deploy a linux vm
  computer_name = "vmuataaccocpm0${count.index+1}"
  custom_data = base64encode(jsonencode({
    ignition = {
      config = {
        replace = {
          source = var.master_ignition_url_sas
          verification = {}
        }
      }
      proxy = {}
      security = {
        tls = {}
      }
      timeouts = {}
      version = "3.2.0"
    }
    kernelArguments = {}
    passwd = {}
    storage = {}
    systemd = {}
  }))

  boot_diagnostics {
    storage_account_uri = var.storage_account.primary_blob_endpoint
  }
  tags = {
    environment = var.environment
    project     = var.project
    purpose     = "master machine 0${count.index+1}"
  }
}

