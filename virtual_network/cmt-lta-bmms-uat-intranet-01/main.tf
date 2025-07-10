resource "azurerm_virtual_network" "uat_intranet_01" {
  name = var.vnet_name
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet_cidr
  tags = var.tags
}
resource "azurerm_subnet" "uat_gw_01" {
  name = "snet-lta-bmms-uat-gw-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.intranet_ifw_01_cidr
  depends_on = [azurerm_virtual_network.uat_intranet_01]
}
resource "azurerm_subnet" "uat_api_01" {
  name = "snet-lta-bmms-uat-api-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.intranet_efw_01_cidr
  depends_on = [azurerm_virtual_network.uat_intranet_01]
}
resource "azurerm_subnet" "AzureFirewallSubnet" {
  name = "AzureFirewallSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.intranet_gw_01_cidr
  depends_on = [azurerm_virtual_network.uat_intranet_01]
}

resource "azurerm_public_ip" "uat_firewall_pip" {
  name                = "pip-lta-bmms-uat-fw-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "uat_firewall" {
  name                = "fw-lta-bmms-uat-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  depends_on          = [azurerm_virtual_network.uat_intranet_01]

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.uat_firewall_pip.id
  }

  tags = var.tags
}


# resource "azurerm_firewall" "firewall" {
#   name                = "fw-lta-bmms-uat-01"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   zones               = ["1"]  # Availability Zone 1
#   private_ip_ranges   = ["0.0.0.0/0"]  # Modify as per requirements

#   ip_configuration {
#     name                 = "firewall-ipconfig"
#     subnet_id            = azurerm_subnet.AzureFirewallSubnet.id
#     public_ip_address_id = null  # No public IP as per requirements
#   }
# }

# # Enable Firewall Management NIC
# resource "azurerm_firewall_network_rule_collection" "mgmt_rule" {
#   name                = "mgmt-rules"
#   azure_firewall_name = azurerm_firewall.uat_firewall.name
#   resource_group_name = var.resource_group_name
#   priority            = 100
#   action              = "Allow"

#   rule {
#     name = "AllowMgmtTraffic"
#     source_addresses = [
#       "10.0.0.0/16" # Adjust to your management subnet
#     ]
#     destination_ports = ["443"]
#     destination_addresses = [
#       "AzureFirewallManagement"
#     ]
#     protocols = ["TCP"]
#   }
# }
