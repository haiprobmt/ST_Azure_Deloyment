data "azurerm_virtual_network" "uat_intranet_01" {
  resource_group_name = var.intranet_rg_name
  name                = var.intranet_vnet_name
}

data "azurerm_resource_group" "intranet_rg" {
  name = var.intranet_rg_name
}

data "azurerm_virtual_network" "uat_application_01" {
  resource_group_name = var.application_rg_name
  name                = var.application_vnet_name
}

data "azurerm_resource_group" "application_rg" {
  name = var.application_rg_name
}

resource "azurerm_virtual_network_peering" "intranet_peering" {
  name                      = "peer_intranet_to_application"
  resource_group_name       = data.azurerm_resource_group.intranet_rg.name
  virtual_network_name      = data.azurerm_virtual_network.uat_intranet_01.name
  remote_virtual_network_id = data.azurerm_virtual_network.uat_application_01.id
}

resource "azurerm_virtual_network_peering" "application_peering" {
  name                      = "peer_application_to_intranet"
  resource_group_name       = data.azurerm_resource_group.application_rg.name
  virtual_network_name      = data.azurerm_virtual_network.uat_application_01.name
  remote_virtual_network_id = data.azurerm_virtual_network.uat_intranet_01.id
}