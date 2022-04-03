resource "azurerm_virtual_machine" "vm1" {
  name                  = "sanjuVM"
  resource_group_name   = "TerraformRG"
  location              = "East US"
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_DS1_v2"
  storage_os_disk {
    name = "sanjudisk"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }
  delete_os_disk_on_termination = true
  
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }
  os_profile {
    computer_name  = "trainingsystem"
    admin_username = "trainingadmin"
    admin_password = "Pass123$$"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    "environment" = "dev"
    "tier"        = "frontend"
  }
  
  # This step is to install ansible on newly created VM
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install software-properties-common -y",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",

    ]
    connection {
      type = "ssh"
      user = "trainingadmin"
      password = "Pass123$$"
      host = data.azurerm_public_ip.public1.ip_address
    }
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "sanjuvnet"
  address_space       = ["10.0.0.0/16"]
  location            = "East US"
  resource_group_name = "TerraformRG"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "sanjusubnet"
  resource_group_name  = "TerraformRG"
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "sanjunic"
  location            = "East US"
  resource_group_name = "TerraformRG"

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id =azurerm_public_ip.public1.id
  }
}

resource "azurerm_public_ip" "public1" {
  name = "sanjupublicip"
  resource_group_name = "TerraformRG"
  location = "East US"
  allocation_method = "Static"

  tags = {
    "environment" = "dev"
  }
}

data "azurerm_public_ip" "public1"{
  resource_group_name = "TerraformRG"
  name = azurerm_public_ip.public1.name
}