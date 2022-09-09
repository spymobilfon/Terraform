variable helm_chart_name {
    type        = string
    description = "Helm chart name"
    default     = ""

    validation {
        condition     = length(var.helm_chart_name) > 0
        error_message = "Helm chart name don't be empty."
    }
}

variable helm_release_name {
    type        = string
    description = "Helm release name"
    default     = ""

    validation {
        condition     = length(var.helm_release_name) > 0
        error_message = "Helm release name don't be empty."
    }
}

variable helm_release_version {
    type        = string
    description = "Helm chart release version"
    default     = ""

    validation {
        condition     = length(var.helm_release_version) > 0
        error_message = "Helm chart release version don't be empty."
    }
}

variable helm_release_values {
    type        = any
    description = "Helm release values (any type)"
}

variable helm_release_namespace {
    type        = string
    description = "Helm release namespace"
    default     = ""

    validation {
        condition     = length(var.helm_release_namespace) > 0
        error_message = "Helm release namespace don't be empty."
    }
}

variable helm_repository {
    type        = string
    description = "Helm repository address e.g. 'https://azurecontainerregistry.azurecr.io/helm/v1/repo'"
    default     = "https://azurecontainerregistry.azurecr.io/helm/v1/repo"
}

variable helm_repository_username {
    type        = string
    description = "Helm repository username for authentication"
    default     = ""

    validation {
        condition     = length(var.helm_repository_username) > 0
        error_message = "Helm repository username for authentication don't be empty."
    }
}

variable helm_repository_password {
    type        = string
    description = "Helm repository password for authentication"
    default     = ""

    sensitive   = true

    validation {
        condition     = length(var.helm_repository_password) > 0
        error_message = "Helm repository password for authentication don't be empty."
    }
}

variable helm_release_wait {
    type        = bool
    description = "Will wait until all resources are in a ready state before marking the release as successful"
    default     = true
}

variable helm_release_replace {
    type        = bool
    description = "Re-use the given name, only if that name is a deleted release which remains in the history"
    default     = true
}

variable helm_release_atomic {
    type        = bool
    description = "If set, installation process purges chart on fail"
    default     = true
}

variable helm_release_cleanup_on_fail {
    type        = bool
    description = "Allow deletion of new resources created in this upgrade when upgrade fails"
    default     = true
}

variable helm_release_timeout {
    type        = number
    description = "Time in seconds to wait for any individual kubernetes operation"
    default     = 300
}

terraform {
    required_providers {
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.0"
        }
    }
}

resource "helm_release" "main" {
    name                = var.helm_release_name
    repository          = var.helm_repository
    chart               = var.helm_chart_name
    version             = var.helm_release_version
    repository_username = var.helm_repository_username
    repository_password = var.helm_repository_password
    replace             = var.helm_release_replace
    atomic              = var.helm_release_atomic
    cleanup_on_fail     = var.helm_release_cleanup_on_fail
    namespace           = var.helm_release_namespace
    wait                = var.helm_release_wait
    timeout             = var.helm_release_timeout
    create_namespace    = true
    values = [
        yamlencode(var.helm_release_values)
    ]
}

output status {
    value = helm_release.main.status
}
