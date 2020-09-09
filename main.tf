resource "azurerm_resource_group" "labgrid-vnet" {
  name     = "labgrid-devops-network"
  location = "centralus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aci-devops"
  address_space       = ["10.254.0.0/16"]
  location            = "centralus"
  resource_group_name = azurerm_resource_group.labgrid-vnet.name

}

resource "azurerm_subnet" "aci-subnet" {
  name                 = "aci-subnet"
  resource_group_name  = azurerm_resource_group.labgrid-vnet.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.254.1.0/24"]

  delegation {
    name = "acidelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.labgrid-vnet.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "labgridPublicIP"
  location            = "centralus"
  resource_group_name = azurerm_resource_group.labgrid-vnet.name
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "rg-aci-devops"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
}

resource "azurerm_application_gateway" "network" {
  name                = "labgrid-appgateway"
  resource_group_name = azurerm_resource_group.labgrid-vnet.name
  location            = azurerm_resource_group.labgrid-vnet.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

module "aci-devops-agent" {
  source                = "Azure/aci-devops-agent/azurerm"
  resource_group_name   = "rg-aci-devops"
  location              = "centralus"
  create_resource_group = true

  enable_vnet_integration  = true
  vnet_resource_group_name = azurerm_resource_group.labgrid-vnet.name
  vnet_name                = azurerm_virtual_network.vnet.name
  subnet_name              = azurerm_subnet.aci-subnet.name

  linux_agents_configuration = {
    agent_name_prefix = "linuxagent"
    count             = 5
    docker_image      = "kathrynloving/explorable-labs-full"
    docker_tag        = "1.0.4"
    agent_pool_name   = "private-aci-pool"
    cpu               = 1
    memory            = 4
    container_port    = 5000
  }
  azure_devops_org_name              = "labgrid"
  azure_devops_personal_access_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXX"

  image_registry_credential = {
    username = "XXXXXXXXXXXXXXX"
    password = "XXXXXXXXXXXXXXX"
    server   = "index.docker.io"
  }
}
