terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
    name     = var.resource_group
    location = var.location

    tags = var.custom_tags
}

resource "azurerm_virtual_network" "main" {
    name                = "${var.resource_group}-net"
    location            = var.location
    resource_group_name = azurerm_resource_group.main.name
    address_space       = ["10.10.0.0/16"]

    tags = var.custom_tags
}

resource "azurerm_subnet" "main" {
    name                 = "${var.resource_group}-subnet"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_public_ip" "main" {
    name                = "${var.resource_group}-public-ip"
    location            = var.location
    resource_group_name = azurerm_resource_group.main.name
    allocation_method   = "Static"
    domain_name_label   = var.domain_name_prefix

    tags = var.custom_tags
}

resource "azurerm_network_security_group" "main" {
    name                = "${var.resource_group}-nsg"
    location            = var.location
    resource_group_name = azurerm_resource_group.main.name

    dynamic "security_rule" {
        for_each = var.nsg_rules

        content {
            name                       = security_rule.value["name"]
            priority                   = security_rule.value["priority"]
            direction                  = security_rule.value["direction"]
            access                     = security_rule.value["access"]
            protocol                   = security_rule.value["protocol"]
            source_port_range          = security_rule.value["source_port_range"]
            destination_port_range     = security_rule.value["destination_port_range"]
            source_address_prefix      = security_rule.value["source_address_prefix"]
            destination_address_prefix = security_rule.value["destination_address_prefix"]
        }
    }

    tags = var.custom_tags
}

resource "azurerm_network_interface" "main" {
    name                 = "${var.resource_group}-nic"
    location             = var.location
    resource_group_name  = azurerm_resource_group.main.name
    enable_ip_forwarding = true

    ip_configuration {
        name                          = "${var.resource_group}-nic-conf"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.main.id
    }

    tags = var.custom_tags
}

resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_linux_virtual_machine" "main" {
    name                  = var.vm_name
    location              = var.location
    resource_group_name   = azurerm_resource_group.main.name
    network_interface_ids = [azurerm_network_interface.main.id]
    size                  = var.vm_size
    admin_username        = var.user_name
    disable_password_authentication = true

    os_disk {
        name                 = "${var.vm_name}-os-disk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "18.04.202109130"
    }

    admin_ssh_key {
        username   = var.user_name
        public_key = file("~/.ssh/id_rsa.pub")
    }

    custom_data = base64encode(templatefile(
        "${path.module}/custom-init.sh",
        {
            user_name = var.user_name,
            remote_address = azurerm_public_ip.main.fqdn,
            client_count = var.client_count
        }
    ))

    tags = var.custom_tags
}

resource "null_resource" "wait_finish" {
    connection {
        type        = "ssh"
        host        = azurerm_public_ip.main.fqdn
        port        = 22
        user        = var.user_name
        timeout     = "5m"
        private_key = file("~/.ssh/id_rsa")
    }

    provisioner "remote-exec" {
        script = "${path.module}/wait-finish.sh"
    }

    depends_on = [azurerm_linux_virtual_machine.main]
}

resource "azurerm_route_table" "main" {
    name                          = "${var.resource_group}-route-table"
    location                      = var.location
    resource_group_name           = azurerm_resource_group.main.name
    disable_bgp_route_propagation = true

    route {
        name                   = "openvpn"
        address_prefix         = "10.10.8.0/24"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = azurerm_network_interface.main.private_ip_address
    }

    tags = var.custom_tags
}

resource "azurerm_subnet_route_table_association" "main" {
    subnet_id      = azurerm_subnet.main.id
    route_table_id = azurerm_route_table.main.id
}

resource "azurerm_consumption_budget_resource_group" "main" {
    name              = "${var.resource_group}-budget"
    resource_group_id = azurerm_resource_group.main.id

    amount     = 1000
    time_grain = "Monthly"

    time_period {
        start_date = "2021-09-01T00:00:00Z"
        end_date   = "2031-01-01T00:00:00Z"
    }

    notification {
        enabled   = true
        threshold = 100
        operator  = "GreaterThan"

        contact_emails = [
            var.email
        ]
    }

    notification {
        enabled   = true
        threshold = 85
        operator  = "GreaterThan"

        contact_emails = [
            var.email
        ]
    }
}
