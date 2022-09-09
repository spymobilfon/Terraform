variable tenant_id {
  type        = string
  description = "Azure AD Tenant ID"
  default     = ""

  validation {
    condition     = length(var.tenant_id) > 0
    error_message = "Azure AD Tenant ID don't be empty."
  }
}

variable subscription_id {
  type        = string
  description = "Azure Subscription ID"
  default     = ""

  validation {
    condition     = length(var.subscription_id) > 0
    error_message = "Azure Subscription ID don't be empty."
  }
}

variable certificates_path {
  type        = string
  description = "Path to certificates"
  default     = ""

  validation {
    condition     = length(var.certificates_path) > 0
    error_message = "Path to certificates don't be empty."
  }
}

variable aks {
    type = map(object({
        is_enabled              = bool
        aks_cluster_name        = string
        aks_resource_group_name = string
    }))
    description = "Target AKS cluster information"
}

locals {
    aks_for_deploy = {
        for key in keys(var.aks):
        key => var.aks[key]
        if var.aks[key].is_enabled
    }
}

module "aks_configuration" {
    source              = "./../service_azure_cloud_resources/service_aks_cluster"
    for_each            = local.aks_for_deploy
    aks_cluster_name    = each.value.aks_cluster_name
    aks_resource_group_name = each.value.aks_resource_group_name
}

locals {
    aks_clusters_with_configurations = [
        for value in module.aks_configuration : value.aks_cluster_configuration
    ]
}

output "aks_configurations" {
    value     = local.aks_clusters_with_configurations
    sensitive = true
}
