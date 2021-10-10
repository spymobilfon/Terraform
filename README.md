# Terraform

## openvpn-azure-vm
OpenVPN server deployment on Azure VM based on Ubuntu 18.04 LTS with generating certificates and clients configurations.

Input variables:
- `resource_group` - Azure resource group name;
- `location` - Azure resource location
- `custom_tags` - Azure resource tags;
- `vm_name` - Azure VM name;
- `vm_size` - Azure VM size;
- `user_name` - OS user name;
- `domain_name_prefix` - Domain name prefix linked with public IP;
- `nsg_rules` - Azure NSG rule;
- `client_count` - OpenVPN client count;
- `email` - Email for notifications.

Example:
```
resource_group     = "rg1"
location           = "westeurope"
vm_name            = "vm1"
vm_size            = "Standard_B1ls"
user_name          = "user1"
domain_name_prefix = "vpn1"
client_count       = 5
email              = "mail@example.org"
```

> You need set current month for `start_date` in `time_period` from resource `azurerm_consumption_budget_resource_group`.
