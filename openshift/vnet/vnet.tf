resource "azurerm_virtual_network" "cluster_vnet" {
  name = var.virtual_network_name
  location = var.location
  resource_group_name = var.network_resource_group_name
  address_space = var.vnet_cidr
  }

resource "azurerm_subnet" "master_subnet" {
  count = var.preexisting_network ? 0 : 1

  resource_group_name = var.network_resource_group_name
  address_prefixes = var.master_subnet_cidrs
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  name                 = var.master_subnet
}

resource "azurerm_subnet" "worker_subnet" {
  count = var.preexisting_network ? 0 : 1

  resource_group_name = var.network_resource_group_name
  address_prefixes = var.worker_subnet_cidrs
  virtual_network_name = azurerm_virtual_network.cluster_vnet.name
  name                 = var.worker_subnet
}
