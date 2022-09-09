variable "aks_cluster_name" {
    type        = string
    description = "AKS cluster name"
    default     = ""

    validation {
        condition     = length(var.aks_cluster_name) > 0
        error_message = "AKS cluster name don't be empty."
    }
}

variable "aks_resource_group_name" {
    type        = string
    description = "AKS cluster resource group name"
    default     = ""

    validation {
        condition     = length(var.aks_resource_group_name) > 0
        error_message = "AKS cluster resource group name don't be empty."
    }
}

data "azurerm_kubernetes_cluster" "aks_configuration" {
    name                = var.aks_cluster_name
    resource_group_name = var.aks_resource_group_name
}

output "aks_cluster_configuration" {
    value = {
        name                  = var.aks_cluster_name
        kube_admin_config     = data.azurerm_kubernetes_cluster.aks_configuration.kube_admin_config
        kube_config           = data.azurerm_kubernetes_cluster.aks_configuration.kube_config
        kube_admin_config_raw = data.azurerm_kubernetes_cluster.aks_configuration.kube_admin_config_raw
        kube_config_raw       = data.azurerm_kubernetes_cluster.aks_configuration.kube_config_raw
        kubernetes_version    = data.azurerm_kubernetes_cluster.aks_configuration.kubernetes_version
        location              = data.azurerm_kubernetes_cluster.aks_configuration.location
    }
    sensitive = true
}
