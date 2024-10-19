// 既存のサブネットを参照
locals {
  subnet_prefix      = "${var.azure_vnet.name}-"
  azure_subnet_names = { for i in var.azure_subnet_map_list : i.name => "${local.subnet_prefix}${i.name}" }
}

data "azurerm_subnet" "existing" {
  for_each = local.azure_subnet_names

  name                 = each.value
  virtual_network_name = var.azure_vnet_name
  resource_group_name  = var.Azure.resource_group
}

// ネットワークインターフェースの作成
resource "azurerm_network_interface" "nic" {
  for_each            = data.azurerm_subnet.existing
  name                = "${var.azurevm_setting_props.name}-${each.key}-nic"
  location            = var.Azure.location
  resource_group_name = var.Azure.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.id
    private_ip_address_allocation = var.azure_vm_nic_props
  }
}

// SSHキーの作成
resource "tls_private_key" "myazssh" {
  algorithm = var.azure_ssh_private_key_props.algorithm
  rsa_bits  = var.azure_ssh_private_key_props.rsa_bits
}

resource "azurerm_linux_virtual_machine" "myazvm" {
  for_each            = data.azurerm_subnet.existing
  name                = "${var.azurevm_setting_props.name}-${each.key}"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  size                = var.azurevm_setting_props.size
  admin_username      = var.azurevm_setting_props.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  admin_ssh_key {
    username   = var.azurevm_setting_props.admin_username
    public_key = tls_private_key.myazssh.public_key_openssh
  }

  os_disk {
    caching              = var.azurevm_setting_props.os_disk.caching
    storage_account_type = var.azurevm_setting_props.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.azurevm_setting_props.source_image_reference.publisher
    offer     = var.azurevm_setting_props.source_image_reference.offer
    sku       = var.azurevm_setting_props.source_image_reference.sku
    version   = var.azurevm_setting_props.source_image_reference.version
  }
}
