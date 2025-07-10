data "azurerm_virtual_network" "uat_internet_01" {
  resource_group_name = var.internet_rg_name
  name                = var.internet_vnet_name
}

data "azurerm_resource_group" "internet_rg" {
  name = var.internet_rg_name
}

data "azurerm_virtual_network" "uat_application_01" {
  resource_group_name = var.application_rg_name
  name                = var.application_vnet_name
}

data "azurerm_resource_group" "application_rg" {
  name = var.application_rg_name
}

resource "azurerm_virtual_network_peering" "internet_peering" {
  name                      = "peer_internet_to_application"
  resource_group_name       = data.azurerm_resource_group.internet_rg.name
  virtual_network_name      = data.azurerm_virtual_network.uat_internet_01.name
  remote_virtual_network_id = data.azurerm_virtual_network.uat_application_01.id
}

resource "azurerm_virtual_network_peering" "application_peering" {
  name                      = "peer_application_to_internet"
  resource_group_name       = data.azurerm_resource_group.application_rg.name
  virtual_network_name      = data.azurerm_virtual_network.uat_application_01.name
  remote_virtual_network_id = data.azurerm_virtual_network.uat_internet_01.id
}