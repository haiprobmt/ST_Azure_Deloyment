output "data_collection_rule_windows_id" {
  value = azurerm_monitor_data_collection_rule.vminsights-windows.id
}

output "data_collection_rule_linux_id" {
  value = azurerm_monitor_data_collection_rule.vminsights-linux.id
}

# output "data_collection_rule_palo_alto_id" {
#   value = azurerm_monitor_data_collection_rule.vminsights-palo-alto.id
# }

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.analytics_workspace.id
}

# output ddos_protection_plan_id {
#     value = azurerm_network_ddos_protection_plan.ddos_plan.id
# }