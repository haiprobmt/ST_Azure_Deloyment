resource "azurerm_subnet" "uat_gw_01" {
  name                 = "snet-lta-bmms-uat-gw-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.internet_gw_01_cidr
}

resource "azurerm_public_ip" "public_ip" {
  name                = "appgateway-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  ddos_protection_mode = "Enabled"
  ddos_protection_plan_id = var.ddos_protection_plan_id
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = "appgateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.uat_gw_01.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendIpConfig"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  backend_address_pool {
    name = "backendAddressPool"
  }

  backend_http_settings {
    name                  = "backendHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "frontendIpConfig"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "defaultRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpListener"
    backend_address_pool_name  = "backendAddressPool"
    backend_http_settings_name = "backendHttpSettings"
    priority                   = 100 # Assign a unique priority
  }

  url_path_map {
    name                             = "urlPathMap"
    default_backend_address_pool_name = "backendAddressPool"
    default_backend_http_settings_name = "backendHttpSettings"

    path_rule {
      name                       = "examplePathRule"
      paths                      = ["/example/*"]
      backend_address_pool_name  = "backendAddressPool"
      backend_http_settings_name = "backendHttpSettings"
    }
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = var.tags
}
