variable "resource_group" {
    type        = string
    description = "Azure resource group name"
    default     = ""

    validation {
        condition     = length(var.resource_group) > 0
        error_message = "Azure resource group name don't be empty."
    }
}

variable "location" {
    type        = string
    description = "Azure resource location"
    default     = ""

    validation {
        condition     = length(var.location) > 0
        error_message = "Azure resource location don't be empty."
    }
}

variable "custom_tags" {
    type        = map(string)
    description = "Azure resource tags"
    default = {
        env = "home"
        system = "openvpn"
    }
}

variable "vm_name" {
    type        = string
    description = "Azure VM name"
    default     = "ubuntu"
}

variable "vm_size" {
    type        = string
    description = "Azure VM size"
    default     = "Standard_B1ls"
}

variable "user_name" {
    type        = string
    description = "OS user name"
    default     = "ubuntu"
}

variable "domain_name_prefix" {
    type        = string
    description = "Domain name prefix linked with public IP"
    default     = "ubuntu"
}

variable "nsg_rules" {
    description = "Azure NSG rules"
    type = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
    }))
    default = [{
        name                       = "SSH"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    },
    {
        name                       = "OpenVPN"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Udp"
        source_port_range          = "*"
        destination_port_range     = "1194"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }]
}

variable "client_count" {
    type        = number
    description = "OpenVPN client count"
    default     = 1
}

variable "email" {
    type        = string
    description = "Email for notifications"
    default     = ""

    validation {
        condition     = length(var.email) > 0
        error_message = "Email for notifications don't be empty."
    }
}
