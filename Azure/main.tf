provider "azurerm" {
  features {}
}

locals {
  data_inputs = {
  }
}

resource "azurerm_resource_group" "example" {
    name = "terraform-rg-PK"
    location = "polandcentral"
}


resource "azurerm_virtual_network" "example" {
    name = "terraform-example-network"
    address_space = ["10.0.0.0/16"]
    location =  azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
    name =  "terraform-example-subnet"
    resource_group_name = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
    address_prefixes = ["10.0.1.0/24"]
 
}

resource "azurerm_network_interface" "example" {
    name = "terraform-example-nic"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name

    ip_configuration {
      name                          = "terraform-example-ipconfig"
      subnet_id                     = azurerm_subnet.example.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.example.id
    }
}



resource "azurerm_linux_virtual_machine" "example" {
  name                = "terraform-example-vm"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "Password1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  # custom_data    = filebase64(templatefile("userdata.sh", {
  #   server_port = var.server_port
  # }))
  custom_data = base64encode(
    <<-EOF
      #!/bin/bash
      echo "witaj, swiecie" > index.html
      server_port=${var.server_port}
      nohup busybox httpd -f -p "$server_port" &
    EOF
  )

  os_disk {
    name              = "terraform-example-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "example" {
  name                = "terraform-example-publicip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "example" {
  name                = "terraform-example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "Allow_Inbound_TCP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.server_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.example.public_ip_address
  description = "Publiczny adres IP serwera WWW"
  
}