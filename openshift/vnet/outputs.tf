output "virtual_network_id" {
  value = azurerm_virtual_network.cluster_vnet.id
}

output "master_subnet_id" {
  value = azurerm_subnet.master_subnet[0].id
}

output "worker_subnet_id" {
  value = azurerm_subnet.worker_subnet[0].id
}

output "master_subnet" {
  value = azurerm_subnet.master_subnet[0].name
}

output "worker_subnet" {
  value = azurerm_subnet.worker_subnet[0].name
}