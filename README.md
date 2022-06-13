# Terraform

## openvpn-azure-vm
OpenVPN server deployment on Azure VM based on Ubuntu 18.04 LTS with generating certificates and clients configurations.

Input variables:
- `resource_group` - Azure resource group name;
- `location` - Azure resource location;
- `custom_tags` - Azure resource tags;
- `vm_name` - Azure VM name;
- `vm_size` - Azure VM size;
- `user_name` - OS user name;
- `domain_name_prefix` - Domain name prefix linked with public IP;
- `nsg_rules` - Azure NSG rule;
- `client_count` - OpenVPN client count;
- `email` - Email for notifications;
- `budget_start_date` - Start date of consumption budget (example 2021-09-01T00:00:00Z), value should be the current date.

Example file with input values (`terraform.tfvars`):
```
resource_group     = "rg1"
location           = "westeurope"
vm_name            = "vm1"
vm_size            = "Standard_B1ls"
user_name          = "user1"
domain_name_prefix = "vpn1"
client_count       = 5
email              = "mail@example.org"
budget_start_date  = "2021-09-01T00:00:00Z"
```

## aks
Azure Kubernetes Service cluster deployment.

### local

1. Set location
```
cd aks/terraform/local
```
2. Init terraform
```
terraform init
```
3. Apply terraform
```
terraform apply
```
4. For remove all resources
```
terraform destroy
```

Example file with input values (`terraform.tfvars`), should be create in root folder with project:
```
location              = "northeurope"
kubernetes_version    = "1.19.13"
sp_app_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
sp_secret             = "cHaNgE_Me_1"
cert_manager_version  = "1.6.1"
ingress_nginx_version = "4.0.13"
email                 = "mail@example.org"
custom_tags = {
    env = "dev"
    owner = "devops"
    project = "project"
    system = "aks"
}
```

For each terraform variables in file `variables.tf` defined description.
