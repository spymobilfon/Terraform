inputs = {

    # General information
    tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    # Paths
    certificates_path = "${get_terragrunt_dir()}/../../../certificates/"

    # Helm settings
    helm_settings = {
        chart_name               = "prometheus-msteams"
        release_name             = "prometheus-msteams"
        release_namespace        = "monitoringv2"
        version                  = ""
        helm_repository_username = ""
        helm_repository_password = ""
    }

    # Helm release values
    helm_release_values = {
        "aks1": {
            "image": {
                "repository": "quay.io/prometheusmsteams/prometheus-msteams",
                "tag": "v1.5.0"
            },
            "resources": {
                "requests": {
                    "cpu": "10m",
                    "memory": "16Mi"
                },
                "limits": {
                    "cpu": "20m",
                    "memory": "32Mi"
                }
            },
            "metrics": {
                "serviceMonitor": {
                    "enabled": true
                    "additionalLabels": {
                        "release": "cloud-prometheus"
                    },
                    "scrapeInterval": "30s"
                }
            },
            "connectors": [
                {
                    "silent": ""
                },
                {
                    "watchdog": ""
                }
            ],
            "connectorsWithCustomTemplates": [
                {
                    "request_path": "/high",
                    "webhook_url": "",
                    "escape_underscores": true,
                    "template_file": "${file("../../template-card/common-alert-card.tmpl")}"
                },
                {
                    "request_path": "/low",
                    "webhook_url": "",
                    "escape_underscores": true,
                    "template_file": "${file("../../template-card/common-alert-card.tmpl")}"
                },
                {
                    "request_path": "/host",
                    "webhook_url": "",
                    "escape_underscores": true,
                    "template_file": "${file("../../template-card/host-alert-card.tmpl")}"
                },
                {
                    "request_path": "/web",
                    "webhook_url": "",
                    "escape_underscores": true,
                    "template_file": "${file("../../template-card/default-card.tmpl")}"
                }
            ]
        }
    }

    # Target AKS cluster information
    aks = {
        "aks1": {
            "is_enabled": true,
            "aks_cluster_name": "aks1",
            "aks_resource_group_name": "aks1"
        }
    }

}
