resource "azurerm_virtual_network" "uat_application_01" {
  name = var.vnet_name
  location = var.location
  resource_group_name = var.resource_group_name
  address_space = var.vnet_cidr
  ddos_protection_plan {
    id = var.ddos_protection_plan_id
    enable = true
  }
  tags = var.tags
}
resource "azurerm_subnet" "uat_ap_01" {
  name = "snet-lta-bmms-uat-ap-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.ap_01_cidr
  depends_on = [azurerm_virtual_network.uat_application_01]
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "uat_ac_01" {
  name = "snet-lta-bmms-uat-ac-01"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.ac_01_cidr
  depends_on = [azurerm_virtual_network.uat_application_01]
  service_endpoints = ["Microsoft.Storage"]
}
resource "azurerm_subnet" "uat_ac_02" {
  name = "snet-lta-bmms-uat-ac-02"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.ac_02_cidr
  depends_on = [azurerm_virtual_network.uat_application_01]
}
resource "azurerm_subnet" "uat_ac_03" {
  name = "snet-lta-bmms-uat-ac-03"
  resource_group_name = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes = var.ac_03_cidr
  depends_on = [azurerm_virtual_network.uat_application_01]
}

# Create a dedicated subnet for Private Endpoint
resource "azurerm_subnet" "uat_sa_03" {
  name                 = "snet-lta-bmms-uat-sa-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.sa_01_cidr
  service_endpoints = ["Microsoft.Storage"]
  depends_on = [azurerm_virtual_network.uat_application_01]  
}

# resource "azurerm_subnet" "uat_sa_ac_02" {
#   name                 = "snet-lta-bmms-uat-sa-ac-02"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = var.vnet_name
#   address_prefixes     = var.sa_ac_02_cidr
#   service_endpoints = ["Microsoft.Storage"]
#   depends_on = [azurerm_virtual_network.uat_application_01]  
# }

# Create a Subnet for Private Endpoints (Disable Private Link Service Network Policies)
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "kv-private-endpoint-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["172.16.2.192/26"]
  depends_on = [azurerm_virtual_network.uat_application_01]
  private_link_service_network_policies_enabled = true
  service_endpoints = ["Microsoft.KeyVault"]
}

# # Create a dedicated subnet for Private Endpoint
# resource "azurerm_subnet" "uat_machine_03" {
#   name                 = "snet-lta-bmms-uat-machine-01"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = var.vnet_name
#   address_prefixes     = var.machine_01_cidr
#   depends_on = [azurerm_virtual_network.uat_application_01]  
# }

resource "azurerm_network_security_group" "uat_nsg" {
  name                = "sgrp-lta-bmms-uat-application-01"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowInbound101"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefixes     = ["20.184.16.181", "172.16.3.36"]
    destination_address_prefix = "172.16.2.64"
    # description                = "Allow MAS Data Traffic Inbound"
  }

  security_rule {
    name                       = "AllowInbound102"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.2.64"
    destination_address_prefix = "172.16.2.128"
    # description                = "Allow MAS Data Traffic Inbound"
  }

  security_rule {
    name                       = "AllowInbound103"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes =  ["172.16.2.128", "172.16.2.160"]
    # description                = "Allow MAS Data Traffic Inbound"
  }

  security_rule {
    name                       = "AllowCommunicationControlPlanMachine"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6443"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.2.64"
    destination_address_prefix = "172.16.2.128"
    description                = "Allows communication to the control plane machines"
  }

  security_rule {
    name                       = "AllowInternalCommunicationControlPlanMachine"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6443-22623"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefix = "172.16.2.64"
    description                = "Allows internal communication to the machine config server for provisioning machines"
  }

  security_rule {
    name                       = "AllowMetrics"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "1936"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Metrics"
  }

  security_rule {
    name                       = "AllowHostLevelServices202"
    priority                   = 202
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9000-9999"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Host level services, including the node exporter on ports 9100-9101 and the Cluster Version Operator on port 9099"
  }

  security_rule {
    name                       = "AllowKubernetes"
    priority                   = 203
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "10250-10259"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "The default ports that Kubernetes reserves"
  }

  security_rule {
    name                       = "AllowOpenshiftSDN"
    priority                   = 204
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "10256"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "openshift-sdn"
  }

  security_rule {
    name                       = "AllowKVXLAN"
    priority                   = 205
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "4789"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "VXLAN"
  }

  security_rule {
    name                       = "AllowGeneve"
    priority                   = 206
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "6081"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Geneve"
  }

  security_rule {
    name                       = "AllowHostLevelServices207"
    priority                   = 207
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "9000-9999"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Host level services, including the node exporter on ports 9100-9101"
  }

  security_rule {
    name                       = "AllowIPsecIKE"
    priority                   = 208
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "500"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec IKE packets"
  }

  security_rule {
    name                       = "AllowIPsecNAT-T"
    priority                   = 209
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "4500"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec NAT-T packets"
  }

  security_rule {
    name                       = "AllowNTP"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowKubernetesNodePort-tcp"
    priority                   = 211
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "30000-32767"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Kubernetes node port TCP"
  }

  security_rule {
    name                       = "AllowKubernetesNodePort-udp"
    priority                   = 212
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "30000-32767"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Kubernetes node port UDP"
  }

  security_rule {
    name                       = "AllowIPsecESP"
    priority                   = 213
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Esp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec Encapsulating Security Payload (ESP)"
  }

  security_rule {
    name                       = "AllowNetworkReachabilityTests"
    priority                   = 214
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes      = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Network reachability tests"
  }

  ## Outbound Rules
  security_rule {
    name                       = "AllowOutbound101"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.2.64"
    destination_address_prefix = "172.16.2.128"
    description                = "Allow all outbound traffic"
  }

  security_rule {
    name                       = "AllowOutbound102"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "443"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Allow all outbound traffic"
  }

  security_rule {
    name                       = "AllowOutbound103"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6443-22623"
    destination_port_range     = "*"
    source_address_prefix      = "172.16.2.64"
    destination_address_prefix = "172.16.2.128"
    description                = "Allows communication to the control plane machines"
  }

  security_rule {
    name                       = "AllowInternalOutboundCommunicationControlPlanMachine"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6443-22623"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefix = "172.16.2.64"
    description                = "Allows internal communication to the machine config server for provisioning machines"
  }

  security_rule {
    name                       = "AllowOutboundMetrics"
    priority                   = 201
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "1936"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Metrics"
  }

  security_rule {
    name                       = "AllowOutboundHostLevelServices"
    priority                   = 202
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9000-9999"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Host level services, including the node exporter on ports 9100-9101 and the Cluster Version Operator on port 9099"
  }

  security_rule {
    name                       = "AllowOutboundKubernetes"
    priority                   = 203
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "10250-10259"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "The default ports that Kubernetes reserves"
  }

  security_rule {
    name                       = "AllowOutboundOpenshiftSDN"
    priority                   = 204
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "10256"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "openshift-sdn"
  }

  security_rule {
    name                       = "AllowOutboundVXLAN"
    priority                   = 205
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "4789"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "VXLAN"
  }

  security_rule {
    name                       = "AllowOutboundGeneve"
    priority                   = 206
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "6081"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Geneve"
  }

  security_rule {
    name                       = "AllowOutboundHostLevelServices207"
    priority                   = 207
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "9000-9999"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Host level services, including the node exporter on ports 9100-9101"
  }

  security_rule {
    name                       = "AllowOutboundIPsecIKE"
    priority                   = 208
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "500"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec IKE packets"
  }

  security_rule {
    name                       = "AllowOutboundIPsecNatT"
    priority                   = 209
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "4500"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec NAT-T packets"
  }

  security_rule {
    name                       = "AllowOutboundNTP"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowOutboundKubernetesNodePort-tcp"
    priority                   = 211
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "30000-32767"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Kubernetes node port TCP"
  }

  security_rule {
    name                       = "AllowOutboundKubernetesNodePort-udp"
    priority                   = 212
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "30000-32767"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Kubernetes node port UDP"
  }

  security_rule {
    name                       = "AllowOutboundIPsecESP"
    priority                   = 213
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Esp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "IPsec Encapsulating Security Payload (ESP)"
  }

  security_rule {
    name                       = "AllowOutboundNetworkReachabilityTests"
    priority                   = 214
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefixes = ["172.16.2.128", "172.16.2.160"]
    description                = "Network reachability tests"
  }

  security_rule {
    name                       = "AllowOutboundNTP301"
    priority                   = 301
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "123"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.52"
    description                = "Network Time Protocol (NTP) on UDP port 123"
  }

  security_rule {
    name                       = "AllowOutboundAuthenticationToAD"
    priority                   = 302
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "389-636"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.52"
    description                = "Authentication to Active Directory"
  }

  security_rule {
    name                       = "AllowOutboundDNS-udp"
    priority                   = 303
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.52"
    description                = "DNS UDP"
  }

  security_rule {
    name                       = "AllowOutboundDNS-tcp"
    priority                   = 304
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "53"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.52"
    description                = "DNS TCP"
  }

  security_rule {
    name                       = "AllowOutboundWSUS"
    priority                   = 305
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8501-8531"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.68"
    description                = "WSUS Update"
  }

  security_rule {
    name                       = "AllowOutboundSplunk"
    priority                   = 306
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9998"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.3.20"
    description                = "To send data to Spunk heavy forwarder"
  }

  security_rule {
    name                       = "AllowOutboundAuthenticationToAD307"
    priority                   = 307
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "389-636"
    destination_port_range     = "*"
    source_address_prefixes     = ["172.16.2.128", "172.16.2.160"]
    destination_address_prefix = "172.16.3.68"
    description                = "Authentication to Active Directory"
  }

  security_rule {
    name                       = "AllowOutboundTableau"
    priority                   = 401
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "*"
    source_address_prefix     = "172.16.2.4"
    destination_address_prefix = "172.16.1.132"
    description                = "Tableau Interface"
  }

  tags = var.tags
}