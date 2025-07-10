resource "azurerm_subnet" "subnet_uat_sec_01" {
  name                 = "snet-lta-bmms-uat-sec-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.uat_sec_01_cidr
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic-01"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_uat_sec_01.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  # size                  = "Standard_D4_v5"
  size                  = "Standard_B1ms"
  admin_username        = "adminuser" # Replace with your desired username
  admin_password        = "SecurePassword123!" # Replace with your secure password
  network_interface_ids = [azurerm_network_interface.nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "vmuatmscwablr01-os01"
    # create_option     = "FromImage"
    # managed_disk_type = "Standard_LRS"
    disk_size_gb      = 128  
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk" # Adjust if using Windows Server 2025
    version   = "latest"
  }
  computer_name            = var.vm_name
  # custom_data              = "" # Add if required for additional setup
  provision_vm_agent       = true
  enable_automatic_updates = true
  patch_assessment_mode     = "AutomaticByPlatform"
  patch_mode                = "AutomaticByPlatform"
  tags = var.tags
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "${var.vm_name}-data01"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}

# Install Azure Monitor Agent (AMA) on the VM
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "DependencyAgentWindows"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  settings                   = jsonencode(
  {
    "enableAMA" = "true"
  }
  )
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
}


# Associate the Data Collection Rule (DCR) with the VM
resource "azurerm_monitor_data_collection_rule_association" "dcr_vm" {
  name                    = "vm-dcr-association"
  target_resource_id      = azurerm_windows_virtual_machine.vm.id
  data_collection_rule_id = var.data_collection_rule_windows_id
}

resource "azurerm_monitor_diagnostic_setting" "policy_diagnostics" {
  name                       = "${azurerm_windows_virtual_machine.vm.name}policycompliancelogs"
  target_resource_id         = azurerm_windows_virtual_machine.vm.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # log {
  #   category = "PolicyEvaluationDetails"
  #   enabled  = true
  # }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# # Enable Backup Protection for the VM
# resource "azurerm_backup_protected_vm" "vm_backup" {
#   resource_group_name = var.resource_group_name
#   recovery_vault_name = var.recovery_vault_name
#   source_vm_id        = azurerm_windows_virtual_machine.vm.id
#   backup_policy_id    = var.backup_policy_id
# }

# resource "azurerm_virtual_machine_extension" "guest_configuration_windows" {
#   name                       = "GuestConfiguration"
#   virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
#   publisher                  = "Microsoft.Azure.GuestConfiguration"
#   type                       = "GC"
#   type_handler_version       = "1.29" # Use the latest version available
#   auto_upgrade_minor_version = true
# }

# resource "null_resource" "start_vm" {
#   provisioner "local-exec" {
#     command = "az vm start --resource-group ${var.resource_group_name} --name ${var.vm_name}"
#   }

#   depends_on = [azurerm_windows_virtual_machine.vm]
# }

# resource "azurerm_virtual_machine_extension" "enable_exploit_guard" {
#   name                       = "EnableExploitGuard"
#   virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
#   publisher                  = "Microsoft.Compute"
#   type                       = "CustomScriptExtension"
#   type_handler_version       = "1.10"  # Use the latest version
#   auto_upgrade_minor_version = true

#   settings = jsonencode({
#     "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File ${path.module}/enable_exploit_guard.ps1"
#   })

#   protected_settings = jsonencode({
#     "script" = base64encode(file("${path.module}/enable_exploit_guard.ps1"))
#   })
#   depends_on = [null_resource.start_vm]
# }

# resource "azurerm_virtual_machine_extension" "enable_tls_windows" {
#   name                       = "EnableTLS"
#   virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
#   publisher                  = "Microsoft.Compute"
#   type                       = "CustomScriptExtension"
#   type_handler_version       = "1.10"
#   auto_upgrade_minor_version = true

#   settings = jsonencode({
#     "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File ${path.module}/enable_tls.ps1"
#   })

#   protected_settings = jsonencode({
#     "script" = base64encode(file("${path.module}/enable_tls.ps1")) # Relative path
#   })
#   depends_on = [null_resource.start_vm]
# }
