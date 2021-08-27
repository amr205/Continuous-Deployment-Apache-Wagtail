terraform {
  backend "remote" {
    organization = "amr205"

    workspaces {
      name = "WagtailApache"
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
  name     = "wagtail-apache-rg"
  location = "West US"
}

resource "azurerm_virtual_network" "wagtail-apache" {
  name                = "wagtail-apache-vm"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.wagtail-apache.location
  resource_group_name = azurerm_resource_group.wagtail-apache.name
}

resource "azurerm_subnet" "wagtail-apache" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.wagtail-apache.name
  virtual_network_name = azurerm_virtual_network.wagtail-apache.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "wagtail-apache" {
  name                = "wagtail-apache-publicip"
  resource_group_name = azurerm_resource_group.wagtail-apache.name
  location            = azurerm_resource_group.wagtail-apache.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "wagtail-apache" {
  name                = "wagtail-apache-nic"
  location            = azurerm_resource_group.wagtail-apache.location
  resource_group_name = azurerm_resource_group.wagtail-apache.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wagtail-apache.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wagtail-apache.id
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
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZXZOzD7Lmkr8hEiCtUmR07wTJgTlEfUmRQ1k/KpbI6WG5WeYCaq/zJAw9F4IiI6XcdmXLvul6a00AtFiCKGj+XudIw9z3i2ha0fOlh1un5C6q7XUh9X+EFKw0Nje4rX6J86gUyNJxzXS/Zmae9nmi/Rz3UADana7mg+lRnuVMnayGvAR+gd5Ulb8ebBOBW2bc9WgGbZMHJVS6pDSgMH6XhQOmQh0QhlyKOqKr0QIId7zhELzE2IpJjXX6dF9jehrE6ycW0I8HMIVt31oZANL4S0aEC2eSIBabunlbhkpQ38xU8yPq6Wyzz/kYtLVfa57c3yiT7uiineq3q/u0eje+xmm1geo1aaSME89hTvrBTyY0XVKL+J5/dprbNHDTCN3joXX6JBlLbgRPVjPv8Bq+XU8MD4HVSlD033UD8uewpuFDT80R80tAFBsoBzwDZwTggzJ4hCQfFwMsBm+9R0jJ4Ny3AUfhxpVybSLwUpUAiLbnapfEpKrSE7eZAEH3aWc= amr205@amr205-Lenovo-Y50-70"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

output "serverip" {
  value = azurerm_linux_virtual_machine.wagtail-apache.public_ip_address
}