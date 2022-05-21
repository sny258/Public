resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_hostname}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_hostname}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# If VM needs to be connected over internet
 resource "azurerm_public_ip" "public" {
   name                = "${var.vm_hostname}-pip"
   resource_group_name = var.resource_group_name
   location            = var.location
   allocation_method   = "Dynamic"
 }

# If NSG is required, below example for RDP connection
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_hostname}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "RDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_hostname}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public.id
  }
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "nsgtonic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Connect NIC to subnet
# resource "azurerm_subnet_network_security_group_association" "nsgtosubnet" {
#   subnet_id                 = azurerm_subnet.subnet.id
#   network_security_group_id = azurerm_network_security_group.nsg.id
# }

# Below module can be used for both Windows & Linux VM provisioning
resource "azurerm_virtual_machine" "vm" {
  name                  = var.vm_hostname
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size                  = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  # storage_image_reference {
  #   publisher = "Canonical"
  #   offer     = "UbuntuServer"
  #   sku       = "18.04-LTS"
  #   version   = "latest"
  # }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vm_hostname}-disk"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "AdminSystem"
    admin_username = "AdminUser"
    admin_password = var.admin_pass
  }

  # os_profile_linux_config {
  #   disable_password_authentication = false
  # }

  os_profile_windows_config {
    timezone                  = "GMT Standard Time"
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    "environment" = var.tags
  }
}