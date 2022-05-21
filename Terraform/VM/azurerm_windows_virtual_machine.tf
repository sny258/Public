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
    protocol                   = "TCP"
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

# block for Windows VM provisioning
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_hostname
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  admin_username        = "AdminUser"
  admin_password        = var.admin_pass
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.vm_hostname}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  tags = {
    "environment" = var.tags
  }
}