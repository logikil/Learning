# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.51.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "learning" {
  name     = "rg-learning"
  location = "East US 2"

  tags = {
    Environment = "Terraform Getting Started"
    Team = "Devops"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "learning" {
  name                = "vnet-network"
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location
  address_space       = ["10.0.0.0/16"]
}

#Create a subnet within the virtual network
resource "azurerm_subnet" "learning" {
  name                 = "snet-internal"
  resource_group_name  = azurerm_resource_group.learning.name
  virtual_network_name = azurerm_virtual_network.learning.name
  address_prefixes     = ["10.0.1.0/24"]
}

#Create vm nic and internal IP configuration
resource "azurerm_network_interface" "learning" {
  name                = "nic-machine"
  location            = azurerm_resource_group.learning.location
  resource_group_name = azurerm_resource_group.learning.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.learning.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create virtual machine
resource "azurerm_linux_virtual_machine" "learning" {
  name                = "vm-machine"
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.learning.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}