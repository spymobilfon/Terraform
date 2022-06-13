terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.88.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.4.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "=1.13.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_pet" "prefix" {
  length = 1
}

locals {
  custom_prefix = "${random_pet.prefix.id}-aks"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.custom_prefix}-rg"
  location = var.location

  tags     = var.custom_tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.custom_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.custom_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                   = "defaultpool"
    node_count             = 2
    vm_size                = "Standard_D2s_v4"
    type                   = "VirtualMachineScaleSets"
    enable_auto_scaling    = false
    enable_host_encryption = false
    enable_node_public_ip  = false
    max_pods               = 200
    orchestrator_version   = var.kubernetes_version
    node_labels            = var.custom_tags

    tags = var.custom_tags
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    outbound_type     = "loadBalancer"
    load_balancer_sku = "Standard"

    load_balancer_profile {
      idle_timeout_in_minutes  = 4
      outbound_ports_allocated = 5000
    }
  }

  service_principal {
    client_id     = var.sp_app_id
    client_secret = var.sp_secret
  }

  role_based_access_control {
    enabled = true
  }

  tags = var.custom_tags
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true
  replace          = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300
  values = [
    file("${path.module}/.resources/cert-manager-values.yaml")
  ]
  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
  namespace        = "ingress-basic"
  create_namespace = true
  replace          = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300
  values = [
    file("${path.module}/.resources/ingress-nginx-values.yaml")
  ]
  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = templatefile(
    "${path.module}/.resources/letsencrypt-cluster-issuer.tpl.yaml",
    {
      "email" = var.email
    }
  )

  depends_on = [
    helm_release.cert_manager
  ]
}
