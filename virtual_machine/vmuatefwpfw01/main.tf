resource "azurerm_subnet" "uat_ifw_01" {
  name = "snet-lta-bmms-uat-ifw-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.internet_ifw_01_cidr
}

resource "azurerm_subnet" "uat_efw_01" {
  name = "snet-lta-bmms-uat-efw-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.internet_efw_01_cidr
}

resource "azurerm_public_ip" "firewall_01" {
  name                = "firewall-pip-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_public_ip" "firewall_02" {
  name                = "firewall-pip-02"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_network_interface" "ifw_firewall" {
  name                = "vmuatefwpfw-01-nic-01"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "vmuatefwpfw-01-nic-01-config"
    subnet_id                     = azurerm_subnet.uat_ifw_01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.firewall_01.id
  }
  tags = var.tags
}

resource "azurerm_network_interface" "efw_firewall" {
  name                = "vmuatefwpfw-01-nic-02"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "vmuatefwpfw-01-nic-02-config"
    subnet_id                     = azurerm_subnet.uat_efw_01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.firewall_02.id
  }
  tags = var.tags
}

resource "azurerm_virtual_machine" "firewall" {
  name                  = "paloalto-firewall"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.ifw_firewall.id, azurerm_network_interface.efw_firewall.id]
  vm_size               = "Standard_D3_v2"
  # vm_size               = "Standard_B1ms"
  primary_network_interface_id = azurerm_network_interface.ifw_firewall.id

  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = "byol" # Change to 'bundle1' or 'bundle2' for PAYG
    version   = "latest"
  }

  storage_os_disk {
    name              = "vmuatefwpfw01-os01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 128  
  }

  os_profile {
    computer_name  = "firewall"
    admin_username = "deeeplabsadmin"
    admin_password = "SecurePassword123!" # Or configure SSH keys
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name      = "byol" # Match the SKU in storage_image_reference
    publisher = "paloaltonetworks"
    product   = "vmseries1"
  }
  tags = var.tags
}

resource "azurerm_route_table" "palo_alto_rt" {
  name                = "palo-alto-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = var.route_table_tags
} 

resource "azurerm_route" "default_route" {
  name                   = "internet-route"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.palo_alto_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.efw_firewall.private_ip_address
}

resource "azurerm_subnet_route_table_association" "trust_route_assoc" {
  subnet_id      = azurerm_subnet.uat_efw_01.id
  route_table_id = azurerm_route_table.palo_alto_rt.id
}

# # Install Azure Monitor Agent (AMA) on the VM
# resource "azurerm_virtual_machine_extension" "ama" {
#   name                       = "DependencyAgentLinux"
#   auto_upgrade_minor_version = true
#   automatic_upgrade_enabled  = true
#   publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
#   settings                   = jsonencode(
#   {
#     "enableAMA" = "true"
#   }
#   )
#   type                       = "DependencyAgentLinux"
#   type_handler_version       = "9.10"
#   virtual_machine_id         = azurerm_virtual_machine.firewall.id
# }


# # Associate the Data Collection Rule (DCR) with the VM
# resource "azurerm_monitor_data_collection_rule_association" "dcr_vm" {
#   name                    = "vm-dcr-association"
#   target_resource_id      = azurerm_virtual_machine.firewall.id
#   data_collection_rule_id = var.data_collection_rule_palo_alto_id
# }
