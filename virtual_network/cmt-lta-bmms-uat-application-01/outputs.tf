output vnet_name {
    value = azurerm_virtual_network.uat_application_01.name
}

output vnet_id {
    value = azurerm_virtual_network.uat_application_01.id
}

output master_subnet {
    value = azurerm_subnet.uat_ap_01.name
}

output worker_subnet {
    value = azurerm_subnet.uat_ac_01.name
}

output "master_subnet_id" {
    value = azurerm_subnet.uat_ap_01.id
}

output "worker_subnet_id" {
    value = azurerm_subnet.uat_ac_01.id
}

output storage_account_subnet {
    value = azurerm_subnet.uat_sa_03.name
}

output "storage_account_subnet_id" {
    value = azurerm_subnet.uat_sa_03.id
}

output "tableau_subnet_id" {
  value = azurerm_subnet.uat_ac_03.id
}

output "function_app_subnet_id" {
  value = azurerm_subnet.uat_ac_02.id
}

output "kv_subnet_id" {
  value = azurerm_subnet.private_endpoint_subnet.id
}