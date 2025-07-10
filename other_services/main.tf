# Azure Loganalytics Workspace
resource "azurerm_log_analytics_workspace" "analytics_workspace" {
    name                = var.analytics_workspace_name
    location            = var.location
    resource_group_name = var.law_rg_name
    sku                 = "PerGB2018"
    retention_in_days   = 30
    tags                = var.tags
}

# # Create Data Collection Rule (DCR) for Syslogs from Palo Alto
# resource "azurerm_monitor_data_collection_rule" "vminsights-palo-alto" {
#   name                = "palo_alto_dcr"
#   location            = var.location
#   resource_group_name = var.law_rg_name

#   destinations {
#     log_analytics {
#       name                = "logAnalyticsDest"
#       workspace_resource_id = azurerm_log_analytics_workspace.analytics_workspace.id
#     }
#   }

#   data_flow {
#     destinations = [ "log-analytics" ]
#     streams      = [ "Microsoft-Event" ]
#   }

#   data_flow {
#     destinations = [ "log-analytics" ]
#     streams      = [ "Microsoft-InsightsMetrics" ]
#   }

#   data_sources {
#     syslog {
#       name               = "palo-alto-syslog"
#       streams            = ["Syslog"]
#       facility_names     = ["auth", "authpriv", "daemon", "local0", "local1"]
#       log_levels         = ["Info", "Warning", "Error", "Critical"]
#     }
#   }
# }


# Data Collection Rules for the Windows VM
resource "azurerm_monitor_data_collection_rule" "vminsights-windows" {
  name                        = "vm-monitoring-dcr"
  resource_group_name         = var.law_rg_name
  location                    = var.location

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-Event" ]
  }

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-InsightsMetrics" ]
  }

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-ServiceMap" ]
  }

  # data_flow {
  #   destinations = [ "monitor-metrics" ]
  #   streams      = [ "Microsoft-InsightsMetrics" ]
  # }

  data_sources {
    extension {
      extension_name     = "DependencyAgent"
      name               = "DependencyAgentDataSource"
      streams            = [ "Microsoft-ServiceMap" ]
    }

    performance_counter {
      counter_specifiers            = [ "\\VmInsights\\DetailedMetrics" ]
      name                          = "insights-metrics"
      sampling_frequency_in_seconds = 60
      streams                       = [
        "Microsoft-InsightsMetrics"
      ]
    }

    windows_event_log {
      name           = "windows-events"
      streams        = [ "Microsoft-Event" ]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }
  }

  destinations {
    # azure_monitor_metrics {
    #   name = "monitor-metrics"
    # }

    log_analytics {
      name                  = "log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.analytics_workspace.id
    }
  }
}

# Data Collection Rules for the Linux VM
resource "azurerm_monitor_data_collection_rule" "vminsights-linux" {
  name                        = "vm-monitoring-dcr-linux"
  resource_group_name         = var.law_rg_name
  location                    = var.location

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-Event" ]
  }

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-InsightsMetrics" ]
  }

  data_flow {
    destinations = [ "log-analytics" ]
    streams      = [ "Microsoft-ServiceMap" ]
  }

  # data_flow {
  #   destinations = [ "monitor-metrics" ]
  #   streams      = [ "Microsoft-InsightsMetrics" ]
  # }

  data_sources {
    extension {
      extension_name     = "DependencyAgent"
      name               = "DependencyAgentDataSource"
      streams            = [ "Microsoft-ServiceMap" ]
    }

    performance_counter {
      counter_specifiers            = [ "\\VmInsights\\DetailedMetrics" ]
      name                          = "insights-metrics"
      sampling_frequency_in_seconds = 60
      streams                       = [
        "Microsoft-InsightsMetrics"
      ]
    }

    windows_event_log {
      name           = "linux-events"
      streams        = [ "Microsoft-Event" ]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]",
        "System!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }
  }

  destinations {
    # azure_monitor_metrics {
    #   name = "monitor-metrics"
    # }

    log_analytics {
      name                  = "log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.analytics_workspace.id
    }
  }
}

# Create sentinel
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.analytics_workspace.id
}


# Function Apps
resource "azurerm_storage_account" "function_app_storage_account" {
  name                     = var.function_app_storage_account_name
  resource_group_name      = var.fa_rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  https_traffic_only_enabled = true
  public_network_access_enabled = false
  shared_access_key_enabled = true
  tags = var.tags
}

resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = "${azurerm_storage_account.function_app_storage_account.name}-pe"
  location            = var.location
  resource_group_name = var.fa_rg_name
  subnet_id           = var.sa_function_app_subnet_id

  private_service_connection {
    name                           = "${azurerm_storage_account.function_app_storage_account.name}-psc"
    private_connection_resource_id = azurerm_storage_account.function_app_storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_storage_account_network_rules" "storage_rules" {
  storage_account_id = azurerm_storage_account.function_app_storage_account.id

  # Disable public access
  default_action = "Deny"

  # Allow access through private endpoint
  bypass = ["AzureServices"]
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.fa_rg_name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  lifecycle {
    ignore_changes = [
      kind
    ]
  }
}

# resource "azurerm_user_assigned_identity" "function_app_identity" {
#   name                = "${var.function_app_python_name}-identity"
#   resource_group_name = var.fa_rg_name
#   location            = var.location
# }

resource "azurerm_function_app" "function_app_python" {
  name                       = var.function_app_python_name
  location                   = var.location
  resource_group_name        = var.fa_rg_name
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.function_app_storage_account.name
  storage_account_access_key = azurerm_storage_account.function_app_storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  client_cert_mode           = "Required"
  https_only                 = true
  # identity {
  #   type         = "UserAssigned"
  #   identity_ids = [azurerm_user_assigned_identity.function_app_identity.id]
  # }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    AzureWebJobsStorage              = "UseDevelopmentStorage=false"
    AzureWebJobsStorage__accountName = azurerm_storage_account.function_app_storage_account.name
    AzureWebJobsStorage__authMode    = "identity"
  }

  site_config {
    linux_fx_version = "python|3.9"
    vnet_route_all_enabled = true
    min_tls_version            = "1.2"
    ip_restriction {
      name                      = "SubnetRestriction"
      action                    = "Allow"
      virtual_network_subnet_id = var.function_app_subnet_id
    }
  }
}

# resource "azurerm_role_assignment" "function_app_storage_role" {
#   scope                = azurerm_storage_account.function_app_storage_account.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.function_app_identity.principal_id
# }


resource "azurerm_monitor_diagnostic_setting" "function_app_diagnostic_setting" {
    name                       = "pythonfunctionappdiagnosticsetting"
    target_resource_id         = azurerm_function_app.function_app_python.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.analytics_workspace.id

    metric {
        category = "AllMetrics"
    }
}

# resource "azurerm_function_app" "function_app_java" {
#   name                       = var.function_app_java_name
#   location                   = var.location
#   resource_group_name        = var.fa_rg_name
#   app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
#   storage_account_name       = azurerm_storage_account.function_app_storage_account.name
#   storage_account_access_key = azurerm_storage_account.function_app_storage_account.primary_access_key
#   os_type                    = "linux"
#   version                    = "~4"
#   app_settings = {
#     FUNCTIONS_WORKER_RUNTIME = "java"
#     JAVA_VERSION             = "17"
#   }

#   site_config {
#     linux_fx_version = "Java|17"
#     vnet_route_all_enabled = true

#     # Add IP restriction to only allow access from the subnet
#     ip_restriction {
#       name                      = "SubnetRestriction"
#       action                    = "Allow"
#       virtual_network_subnet_id = var.function_app_subnet_id
#     }
#   }
# }

# resource "azurerm_monitor_diagnostic_setting" "diagnostic_setting" {
#     name                       = "javafunctionappdiagnosticsetting"
#     target_resource_id         = azurerm_function_app.function_app_python.id
#     log_analytics_workspace_id = var.log_analytics_workspace_id

#     metric {
#         category = "AllMetrics"
#     }
# }


# Key Vaults
# Create an Azure Key Vault
resource "azurerm_key_vault" "key_vault" {
  name                        = var.key_vault_name
  location                    = var.location
  resource_group_name         = var.kv_rg_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      var.kv_subnet_id
    ]
  }
  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_diagnostic_setting" {
  name                       = "${azurerm_key_vault.key_vault.name}diagnosticsetting"
  target_resource_id         = azurerm_key_vault.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analytics_workspace.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Create a Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.kv_rg_name
}

# 🔹 Link Private DNS Zone to VNET
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "kv-private-dns-link"
  resource_group_name   = var.kv_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = var.vnet_id
}

# 🔹 Create a Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "kv-private-endpoint"
  location            = var.location
  resource_group_name = var.kv_rg_name
  subnet_id           = var.kv_subnet_id

  private_service_connection {
    name                           = "kv-private-connection"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-private-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
  }
}

# Container Registry
resource "azurerm_container_registry" "container_registry" {
    name                = var.container_registry_name
    resource_group_name = var.acr_rg_name
    location            = var.location
    sku                 = "Basic"
    admin_enabled       = true
    tags                = var.tags
}

# resource "azurerm_api_management" "api_management" {
#     name                = "apim-lta-bmms-uat-2"
#     location            = var.location
#     resource_group_name = var.apim_rg_name
#     publisher_name      = "david-deeeplabs"
#     publisher_email     = "david.n@deeeplabs.com"
#     sku_name            = "Developer_1"
#     tags                = var.tags
# }

# resource "azurerm_api_management_api" "api_management_api" {
#     name                = "example-api"
#     resource_group_name = var.resource_group_name
#     api_management_name = azurerm_api_management.example.name
#     revision            = "1"
#     display_name        = "Example API"
#     path                = "example"
#     protocols           = ["https"]

#     import {
#         content_format = "swagger-link-json"
#         content_value  = var.api_definition_url
#     }
# }

# resource "azurerm_api_management_api_operation" "example_operation" {
#     operation_id        = "example-operation"
#     api_name            = azurerm_api_management_api.example_api.name
#     api_management_name = azurerm_api_management.example.name
#     resource_group_name = var.resource_group_name
#     display_name        = "Example Operation"
#     method              = "GET"
#     url_template        = "/example"
#     response {
#         status = 200
#         description = "Successful response"
#     }
# }
