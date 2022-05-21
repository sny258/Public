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

# Create (and display) an SSH key
 resource "tls_private_key" "ssh" {
   algorithm = "RSA"
   rsa_bits  = 4096
 }

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_hostname
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.nic.id]
  admin_username        = "AdminUser"
  #admin_password        = var.admin_pass         # if not using SSH auth
  size                  = "Standard_DS1_v2"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                  = "${var.vm_hostname}-disk"
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "AdminUser"
    public_key = tls_private_key.ssh.public_key_openssh
    #public_key =file("~/.ssh/id_rsa.pub")
  }

  tags = {
    "environment" = var.tags
  }
}