resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  name                = "ddos-lta-bmms-uat-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "uat_internet_01" {
  name = var.vnet_name
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet_cidr
  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.ddos_plan.id
    enable = true
  }
  tags = var.tags
}
resource "azurerm_subnet" "uat_public_01" {
  name = "snet-lta-bmms-uat-public-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.internet_public_01_cidr
  depends_on = [azurerm_virtual_network.uat_internet_01]
}

resource "azurerm_network_security_group" "uat_nsg" {
  name                = "sgrp-lta-bmms-uat-internet-01"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowMASDataTrafficInbound"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "22"
    source_address_prefix      = "52.187.68.137"
    destination_address_prefix = "20.184.16.181"
    description                = "Allow MAS Data Traffic Inbound"
  }

  security_rule {
    name                       = "AllowPaloAltoFirewall"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "22"
    source_address_prefix      = "172.16.3.36"
    destination_address_prefix = "20.184.16.181"
    description                = "Allow Palo Alto Firewall"
  }

  security_rule {
    name                       = "AllowVAScanning-tcp"
    priority                   = 302
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.164"
    destination_address_prefix = "20.184.16.181"
    description                = "Allow VA Scanning TCP"
  }

  security_rule {
    name                       = "AllowVAScanning-udp"
    priority                   = 303
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.164"
    destination_address_prefix = "20.184.16.181"
    description                = "Allow VA Scanning UDP"
  }

  security_rule {
    name                       = "AllowMASDataTrafficOutbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "20.184.16.181"
    destination_address_prefix = "172.16.2.64"
    description                = "Allow MAS Data Traffic Outbound"
  }

  security_rule {
    name                       = "AllowNTPOutbound"
    priority                   = 301
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefix      = "20.184.16.181"
    destination_address_prefix = "172.16.3.52"
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowActiveDirectoryOutbound-389"
    priority                   = 302
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "389-636"
    destination_port_range     = "*"
    source_address_prefix      = "20.184.16.181"
    destination_address_prefix = "172.16.3.52"
    description                = "Authentication to Active Directory Port 389"
  }

  security_rule {
    name                       = "AllowDNSOutbound-tcp"
    priority                   = 304
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefix      = "20.184.16.181"
    destination_address_prefix = "172.16.3.52"
    description                = "DNS on TCP port 53"
  }

  security_rule {
    name                       = "AllowDNSOutbound-udp"
    priority                   = 305
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefix      = "20.184.16.181"
    destination_address_prefix = "172.16.3.52"
    description                = "DNS on UDP port 53"
  }
  tags = var.tags
}

# resource "azurerm_subnet_network_security_group_association" "uat_public_01_nsg" {
#   subnet_id                 = azurerm_subnet.uat_public_01.id
#   network_security_group_id = azurerm_network_security_group.uat_nsg.id
# }
