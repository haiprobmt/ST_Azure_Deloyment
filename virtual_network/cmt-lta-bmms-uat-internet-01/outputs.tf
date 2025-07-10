output vnet_name {
    value = azurerm_virtual_network.uat_internet_01.name
}

output ddos_protection_plan_id {
    value = azurerm_network_ddos_protection_plan.ddos_plan.id
}
