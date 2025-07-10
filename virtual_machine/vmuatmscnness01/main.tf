resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_subnet" "subnet_uat_ness_01" {
  name                 = "snet-lta-bmms-uat-ness-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.uat_ness_01_cidr
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic-01"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_uat_ness_01.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    name                 = "vmuatmscnness01_os01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb      = 30
  }

  source_image_reference {
    publisher = "pcloudhosting"
    offer     = "nessus"
    sku       = "nessus"
    version   = "latest"
  }

  plan {
    name      = "nessus"
    publisher = "pcloudhosting"
    product   = "nessus"
  }

  # boot_diagnostics {
  #   enabled = true
  # }
  # patch_assessment_mode     = "AutomaticByPlatform"
  # patch_mode                = "AutomaticByPlatform"
  tags = var.tags
}

# Install Azure Monitor Agent (AMA) on the VM
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "DependencyAgentLinux"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  settings                   = jsonencode(
  {
    "enableAMA" = "true"
  }
  )
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.10"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
}


# Associate the Data Collection Rule (DCR) with the VM
resource "azurerm_monitor_data_collection_rule_association" "dcr_vm" {
  name                    = "vm-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = var.data_collection_rule_linux_id
}

resource "azurerm_monitor_diagnostic_setting" "policy_diagnostics" {
  name                       = "${azurerm_linux_virtual_machine.vm.name}policycompliancelogs"
  target_resource_id         = azurerm_linux_virtual_machine.vm.id
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

# # Enable Backup Protection for Linux VM
# resource "azurerm_backup_protected_vm" "linux_vm_backup" {
#   resource_group_name = var.resource_group_name
#   recovery_vault_name = var.recovery_vault_name
#   source_vm_id        = azurerm_linux_virtual_machine.vm.id
#   backup_policy_id    = var.backup_policy_id
# }

# resource "azurerm_virtual_machine_extension" "guest_configuration_linux" {
#   name                       = "GuestConfiguration"
#   virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
#   publisher                  = "Microsoft.Azure.GuestConfiguration"
#   type                       = "GC"
#   type_handler_version       = "1.29" # Use the latest version available
#   auto_upgrade_minor_version = true
# }

# resource "null_resource" "start_vm" {
#   provisioner "local-exec" {
#     command = "az vm start --resource-group ${var.resource_group_name} --name ${var.vm_name}"
#   }

#   depends_on = [azurerm_linux_virtual_machine.vm]
# }

# resource "azurerm_virtual_machine_extension" "enable_tls_linux" {
#   name                       = "EnableTLS"
#   virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.0"
#   auto_upgrade_minor_version = true

#   settings = jsonencode({
#     "commandToExecute" = "bash ${path.module}/enable_tls.sh"
#   })

#   protected_settings = jsonencode({
#     "script" = base64encode(file("${path.module}/enable_tls.sh")) # Relative path
#   })
#   depends_on = [null_resource.start_vm]
# }
