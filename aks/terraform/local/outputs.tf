output cert_manager_status {
  value = helm_release.cert_manager.status
}

output ingress_nginx_status {
  value = helm_release.ingress_nginx.status
}

output aks_cluster_name {
  value = azurerm_kubernetes_cluster.main.name
}
