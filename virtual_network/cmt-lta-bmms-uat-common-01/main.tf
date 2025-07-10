resource "azurerm_virtual_network" "uat_common_01" {
  name = var.vnet_name
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet_cidr
  tags = var.tags
}

resource "azurerm_network_security_group" "uat_nsg" {
  name                = "cmt-lta-bmms-uat-common-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "AllowInboundNTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.2.128", 
                                    "172.16.2.160", "52.163.211.128", 
                                    "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowInboundAuthentication"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "389-636"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.2.128", 
                                    "172.16.2.160", "52.163.211.128", 
                                    "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "Authentication to Active Directory"
  }

  security_rule {
    name                       = "AllowInboundDNS-TCP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.2.128", 
                                    "172.16.2.160", "52.163.211.128", 
                                    "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "DNS TCP"
  }

  security_rule {
    name                       = "AllowInboundDNS-UDP"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.2.128", 
                                    "172.16.2.160", "52.163.211.128", 
                                    "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "DNS UDP"
  }

  security_rule {
    name                       = "AllowInboundwsus"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8501-8531"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.3.36", 
                                    "172.16.3.52", "172.16.3.20"]
    destination_address_prefix = "172.16.3.68"
    description                = "WSUS Update"
  }

  security_rule {
    name                       = "AllowInboundSplunk"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9998"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.3.36", 
                                    "172.16.3.52", "172.16.3.68"]
    destination_address_prefix = "172.16.3.20"
    description                = "To send data to Spunk heavy forwarder"
  }

  security_rule {
    name                       = "AllowOutboundPaloAlto"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22-443"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.36"
    destination_address_prefix = "52.163.213.68"
    description                = "Access to Palo Alto Firewall"
  }

  security_rule {
    name                       = "AllowOutboundVA-TCP"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.164"
    destination_address_prefixes = ["52.163.213.68", "172.16.2.4", "172.16.3.36",
                                     "172.16.3.52", "172.16.3.68", "172.16.2.128", "172.16.2.160"]
    description                = "VA Scanning TCP"
  }

  security_rule {
    name                       = "AllowOutboundVA-UDP"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.164"
    destination_address_prefixes = ["52.163.213.68", "172.16.2.4", "172.16.3.36",
                                     "172.16.3.52", "172.16.3.68", "172.16.2.128", "172.16.2.160"]
    description                = "VA Scanning UDP"
  }

  security_rule {
    name                       = "AllowOutboundRDP"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.36"
    destination_address_prefix = "172.16.2.4"
    description                = "Remote Desktop Access"
  }

  security_rule {
    name                       = "AllowOutboundOpenshift"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.36"
    destination_address_prefix = "172.16.2.64"
    description                = "Access to Openshift Cluster"
  }

  security_rule {
    name                       = "AllowOutboundWSUS-TCP"
    priority                   = 106
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8501-8531"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.68"
    destination_address_prefix = "172.16.1.132"
    description                = "Access to internet proxy for WSUS update TCP"
  }

    security_rule {
    name                       = "AllowOutboundWSUS-UDP"
    priority                   = 107
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "8501-8531"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.3.68"
    destination_address_prefix = "172.16.1.132"
    description                = "Access to internet proxy for WSUS update UDP"
  }

  security_rule {
    name                       = "AllowOutboundNTP"
    priority                   = 108
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.4", "172.16.2.128", "172.16.2.160", "52.163.211.128",
                                  "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowOutboundAuthentication"
    priority                   = 109
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "389-636"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.4", "172.16.2.128", "172.16.2.160", "52.163.211.128",
                                  "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "Authentication to Active Directory"
  }

  security_rule {
    name                       = "AllowOutboundDNS-TCP"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.4", "172.16.2.128", "172.16.2.160", "52.163.211.128",
                                  "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "DNS TCP"
  }

  security_rule {
    name                       = "AllowOutboundDNS-UDP"
    priority                   = 111
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.4", "172.16.2.128", "172.16.2.160", "52.163.211.128",
                                  "172.16.3.36", "172.16.3.68", "172.16.3.20"]
    destination_address_prefix = "172.16.3.52"
    description                = "DNS UDP"
  }

  security_rule {
    name                       = "AllowOutboundwsus"
    priority                   = 112
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8501-8531"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.3.36", 
                                    "172.16.3.52", "172.16.3.20"]
    destination_address_prefix = "172.16.3.68"
    description                = "WSUS Update"
  }

  security_rule {
    name                       = "AllowOutboundSplunk"
    priority                   = 113
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9998"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.4", "172.16.3.36", 
                                    "172.16.3.52", "172.16.3.68"]
    destination_address_prefix = "172.16.3.20"
    description                = "To send data to Spunk heavy forwarder"
  }
  
  tags = var.tags
}
