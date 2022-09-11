terraform {
  backend "remote" {
    organization = "amr205"

    workspaces {
      name = "AzureDatabaseAdministratorDOA"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}



resource "azurerm_resource_group" "wagtail-apache" {
  name     = "wagtail-apache-resources"
  location = "West US"
}

resource "azurerm_public_ip" "wagtail-apache" {
  name                = "wagtailPublicPublic"
  resource_group_name = azurerm_resource_group.wagtail-apache.name
  location            = azurerm_resource_group.wagtail-apache.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "wagtail-apache" {
  name                 = "wagtail-apache-network"
  address_space        = ["10.0.0.0/16"]
  location             = azurerm_resource_group.wagtail-apache.location
  resource_group_name  = azurerm_resource_group.wagtail-apache.name

}

resource "azurerm_subnet" "wagtail-apache" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.wagtail-apache.name
  virtual_network_name = azurerm_virtual_network.wagtail-apache.name
  address_prefixes     = ["10.0.2.0/24"]

}

resource "azurerm_mssql_server" "wagtail-db-server" {
  name                         = "wagtaildbserver"
  resource_group_name          = azurerm_resource_group.wagtail-apache.name
  location                     = azurerm_resource_group.wagtail-apache.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_database" "wagtail-db" {
  name           = "wagtaildb"
  server_id      = azurerm_mssql_server.wagtail-db-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true

}

resource "azurerm_mssql_firewall_rule" "wagtail-db-server-allowazure" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.wagtail-db-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_network_interface" "wagtail-apache" {
  name                = "wagtail-apache-nic"
  location            = azurerm_resource_group.wagtail-apache.location
  resource_group_name = azurerm_resource_group.wagtail-apache.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wagtail-apache.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.wagtail-apache.id
  }
}

resource "azurerm_linux_virtual_machine" "wagtail-apache" {
  name                = "wagtail-apache-machine"
  resource_group_name = azurerm_resource_group.wagtail-apache.name
  location            = azurerm_resource_group.wagtail-apache.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.wagtail-apache.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyQNwh6kZEG2VTp35+C5J6/RDv2rS9dqNcAKvi6ab7ys4nfeUs+aelIHv6iXW49CJIF7ThmRgxJbVSqTaHKKfZV5B1yrzosEDeqlWmIp9b3tixYoOWpRpNZJmShwnxcTQMz8V4SAw2aRq6VaC7qqXiXiY85fqmsQ4Vpko9TdGgrfKY4NddR73mR7v9uuBrlnzucjq85iSVBR7pUQbikxMwWr/moV9PiYzsMi5ivoAQi+3lpSGLQZyIc6NVgY/EenhbvR+mTwHs7fYEyzCb+zIwCtLK3cZ2xpDO+LYPfIqsdxtVkF6Zr++EHkKiR9Jkta2rNEkbBXoL0HcPnMwJtcCIyd8eqePL9PJ4vRGxcnpRcz4DqH2EtrC6hmrNvx4v32Os0fji7xzD4bwhOER3b5LmIvo0VmMbjopHqXHLcZkrszvkrXwC4zrHO0mPnZTyw7iCEGH+1dfuTnYGdLby/2sSP4y2aSbJR7URsl/8xB+fI0eDa0las5vk2pdiY4vrjpU= amr205@amr205-Lenovo-Y50-70"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

output "server_ip" {
  value = azurerm_linux_virtual_machine.wagtail-apache.public_ip_address
}
