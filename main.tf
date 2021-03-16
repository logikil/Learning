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
  location = var.location

  tags = var.tags
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

#Create a public IP
resource "azurerm_public_ip" "learning" {
  name                = "public-ip"
  location            = azurerm_resource_group.learning.location
  resource_group_name = azurerm_resource_group.learning.name
  allocation_method   = "Static"
}

#Create Network Security Group
resource "azurerm_network_security_group" "learning" {
  name                = "vnet-nsg"
  location            = azurerm_resource_group.learning.location
  resource_group_name = azurerm_resource_group.learning.name
}

#Create Network Security Rule
resource "azurerm_network_security_rule" "learning" {
  name = "SSH"
  priority = "1001"
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  source_address_prefix = "*"
  destination_port_range = "22"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.learning.name
  network_security_group_name = azurerm_network_security_group.learning.name
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
    public_ip_address_id          = azurerm_public_ip.learning.id
  }
}

#Create virtual machine
resource "azurerm_linux_virtual_machine" "learning" {
  name                = "vm-machine"
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.learning.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = lookup(var.sku, var.location)
    version   = "latest"
  }
}

data "azurerm_public_ip" "IP" {
  name = azurerm_public_ip.learning.name
  resource_group_name = azurerm_linux_virtual_machine.learning.resource_group_name
  depends_on = [
    azurerm_linux_virtual_machine.learning
  ]
}