terraform {
    source = "${get_terragrunt_dir()}/../../../modules//cloud_helm"
    extra_arguments "init" {
        commands = [
            "init"
        ]
        arguments = [
            "-reconfigure",
        ]
    }
}

include {
    path = "${get_terragrunt_dir()}/../terraform.deployment.settings.hcl"
}

dependencies {
    paths = ["${get_terragrunt_dir()}/../cloud_resources"]
}

generate "provider" {
    path      = "provider.tf"
    if_exists = "overwrite"
    contents = <<EOF
terraform {
    backend "local" {
        path = "#{TerraformLocalStateRootFolder}/prometheus/operator/prod/helm/terraform.tfstate"
    }
}
EOF
}

locals {
    common_deps        = read_terragrunt_config("${get_terragrunt_dir()}/common_deps.hcl")
    aks_configurations = local.common_deps.dependency.cloud_resources.outputs.aks_configurations
}

inputs = {
    aks_configurations = local.aks_configurations
}

generate "provider_helm" {
    path      = "provider_helm.tf"
    if_exists = "overwrite"
    contents = <<EOT
%{ for key, configuration in local.aks_configurations }
provider "helm" {
    alias = "${configuration.name}"
    kubernetes {
        host                   = "${configuration.kube_config[0].host}"
        client_certificate     = base64decode("${configuration.kube_config[0].client_certificate}")
        client_key             = base64decode("${configuration.kube_config[0].client_key}")
        cluster_ca_certificate = base64decode("${configuration.kube_config[0].cluster_ca_certificate}")
    }
}
%{ endfor }
EOT
}

generate "cloud_helm" {
    path      = "cloud_helm.tf"
    if_exists = "overwrite"
    contents = <<EOT
variable "helm_settings" {
    type        = any
    description = "Helm settings (any type)"

    sensitive   = true
}

variable "helm_release_values" {
    type        = any
    description = "Helm release values (any type)"
}

variable aks_configurations {
    type        = any
    description = "AKS configurations"
}

%{ for key, configuration in local.aks_configurations }
module "helm_release_${configuration.name}" {
    source = "./helm"
    helm_chart_name          = var.helm_settings.chart_name
    helm_release_name        = var.helm_settings.release_name
    helm_release_version     = var.helm_settings.version
    helm_release_namespace   = var.helm_settings.release_namespace
    helm_release_values      = var.helm_release_values["${configuration.name}"]
    helm_repository_username = var.helm_settings.helm_repository_username
    helm_repository_password = var.helm_settings.helm_repository_password
    providers = {
        helm = helm.${configuration.name}
    }
}
%{ endfor }
EOT
}
