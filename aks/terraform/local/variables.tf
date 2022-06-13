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
        env = "dev"
        owner = "devops"
        project = "project"
        system = "aks"
    }
}

variable "kubernetes_version" {
    type        = string
    description = "Kubernetes API version. For checking available versions use command 'az aks get-versions --location AZURE_RESOURCE_LOCATION --output table'"
    default     = "1.19.13"
}

variable "sp_app_id" {
    type        = string
    description = "Service principal application ID"
    default     = ""
}

variable "sp_secret" {
    type        = string
    description = "Service principal secret"
    default     = ""

    sensitive   = true

    validation {
        condition     = length(var.sp_secret) > 0
        error_message = "Service principal secret don't be empty."
    }
}

variable "cert_manager_version" {
    type        = string
    description = "Cert manager helm chart version"
    default     = "1.6.1"
}

variable "ingress_nginx_version" {
    type        = string
    description = "Ingress nginx helm chart version"
    default     = "4.0.13"
}

variable "email" {
    type        = string
    description = "Email address"
    default     = ""

    validation {
        condition     = length(var.email) > 0
        error_message = "Email address don't be empty."
    }
}
