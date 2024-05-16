resource "azurerm_resource_group" "vnetconnection_rg" {
  name     = "${var.prefix}-rg"
  location = var.location[0]
}

resource "azurerm_virtual_network" "vnet-1" {
  name                = "${var.prefix}-vnet1"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  address_space       = ["172.19.0.0/16"]
}

resource "azurerm_subnet" "vnet1_subnet" {
  name                 = "${var.prefix}-vnet1subnet"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["172.19.1.0/24"]
}

resource "azurerm_subnet" "vnet1_gtwsubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnetconnection_rg.name
  virtual_network_name = azurerm_virtual_network.vnet-1.name
  address_prefixes     = ["172.19.2.0/24"]
}

resource "azurerm_public_ip" "vnetgtw1_ip" {
  name                = "${var.prefix}-VNGTW1-ip"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  allocation_method   = var.static_dynamic[0]
 
  sku = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard
#  zones = var.availability_zone

  tags = {
    environment = var.env
  } 

}

resource "azurerm_virtual_network_gateway" "vnetgtw" {
  name                = "${var.prefix}-VNGTW"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw2"
  generation = "Generation2"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.vnetgtw1_ip.id
    private_ip_address_allocation = var.static_dynamic[1]
    subnet_id                     = azurerm_subnet.vnet1_gtwsubnet.id
  }
}

############################################## Create NSG 1 ######################################################

resource "azurerm_network_security_group" "azure_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  security_rule {
    name                       = "azure_nsg11"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "azure_nsg12"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]  

}

################################## Public VM1 in VNet1 #####################################################

resource "azurerm_public_ip" "public_ip1" {
  name                = "${var.prefix}-ip1"
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name
  location            = azurerm_resource_group.vnetconnection_rg.location
  allocation_method   = var.static_dynamic[0]

  sku = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard  
  zones = var.availability_zone

  tags = {
    environment = var.env
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]

}

resource "azurerm_network_interface" "vnet_interface1" {
  name                = "${var.prefix}-nic1"
  location            = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name = azurerm_resource_group.vnetconnection_rg.name

  ip_configuration {
    name                          = "${var.prefix}-ip-configuration"
    subnet_id                     = azurerm_subnet.vnet1_subnet.id
    private_ip_address_allocation = var.static_dynamic[1]
    public_ip_address_id = azurerm_public_ip.public_ip1.id
  }
  
  tags = {
    environment = var.env
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]

}

resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  network_interface_id      = azurerm_network_interface.vnet_interface1.id
  network_security_group_id = azurerm_network_security_group.azure_nsg.id

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]

}

resource "azurerm_virtual_machine" "azure_vm" {
  name                  = "${var.prefix}-vm1"
  location              = azurerm_resource_group.vnetconnection_rg.location
  resource_group_name   = azurerm_resource_group.vnetconnection_rg.name
  network_interface_ids = [azurerm_network_interface.vnet_interface1.id]
  vm_size               = var.vm_size
  zones                 = var.availability_zone

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  #### Boot Diagnostics is Enable with managed storage account ########
  boot_diagnostics {
    enabled = true
    storage_uri = ""
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.disk_size_gb
  }
  os_profile {
    computer_name  = "${var.computer_name}-1"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = filebase64("custom_data.sh") 
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  storage_data_disk {
    name              = "${var.prefix}-datadisk1"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.extra_disk_size_gb
    lun               = 0
    managed_disk_type = "Standard_LRS"
  }
  tags = {
    environment = var.env
  }

  depends_on = [azurerm_virtual_network_gateway.vnetgtw]

}
