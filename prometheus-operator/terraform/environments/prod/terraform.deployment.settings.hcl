inputs = {

    # General information
    tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

    # Paths
    certificates_path = "${get_terragrunt_dir()}/../../../certificates/"

    # Helm settings
    helm_settings = {
        chart_name               = "prometheus-operator"
        release_name             = "cloud-prometheus"
        release_namespace        = "monitoringv2"
        version                  = "#{helm-chart-version}"
        helm_repository_username = "#{helm-repository-username}"
        helm_repository_password = "#{helm-repository-password}"
    }

    # Helm release values
    helm_release_values = {
        "aks1": {
            "cacertificates": {
                "ca.crt": "#{ca-ingress}"
            },
            "thanosStorage": {
                "monStorageName": "thanos",
                "monStorageKey": "#{thanos-storage-key}",
                "monStorageContainerName": "objstore"
            },
            "thanosIngressTls": {
                "certificate": {
                    "tls.crt": "#{aks1-thanos-ingress-public-key}",
                    "tls.key": "#{aks1-thanos-ingress-private-key}"
                }
            },
            "alertmanager": {
                "enabled": false
            },
            "grafana": {
                "enabled": false
            },
            "prometheusOperator": {
                "resources": {
                    "requests": {
                        "cpu": "100m",
                        "memory": "512Mi"
                    },
                    "limits": {
                        "cpu": "100m",
                        "memory": "512Mi"
                    }
                },
                "admissionWebhooks": {
                    "enabled": false
                },
                "tls": {
                    "enabled": false
                },
                "image": {
                    "repository": "quay.io/prometheus-operator/prometheus-operator",
                    "tag": "v0.53.1",
                    "pullPolicy": "IfNotPresent"
                },
                "prometheusConfigReloader": {
                    "image": {
                        "repository": "quay.io/prometheus-operator/prometheus-config-reloader",
                        "tag": "v0.53.1"
                    },
                    "resources": {
                        "requests": {
                            "cpu": "50m",
                            "memory": "50Mi"
                        },
                        "limits": {
                            "cpu": "100m",
                            "memory": "100Mi"
                        }
                    }
                },
                "thanosImage": {
                    "repository": "quay.io/thanos/thanos",
                    "tag": "v0.23.1"
                }
            },
            "prometheus": {
                "prometheusSpec": {
                    "resources": {
                        "requests": {
                            "cpu": "100m",
                            "memory": "2Gi"
                        },
                        "limits": {
                            "cpu": "500m",
                            "memory": "10Gi"
                        }
                    },
                    "retention": "1d",
                    "image": {
                        "repository": "quay.io/prometheus/prometheus",
                        "tag": "v2.32.1"
                    },
                    "thanos": {
                        "image": "quay.io/thanos/thanos:v0.23.1",
                        "version": "v0.23.1",
                        "objectStorageConfig": {
                            "key": "thanos.yaml"
                            "name": "thanos-objstore-config"
                        }
                    },
                    "externalLabels": {
                        "cluster": "aks1"
                    },
                    "serviceMonitorSelector": {
                        "matchLabels": {
                            "release": "cloud-prometheus"
                        }
                    },
                    "additionalAlertManagerConfigs": [
                        {
                            "scheme": "https",
                            "static_configs": [
                                {
                                    "targets": ["alertmanager.example.org:443"]
                                }
                            ],
                            "tls_config": {
                                "insecure_skip_verify": true
                            }
                        }
                    ]
                },
                "thanosIngress": {
                    "enabled": true,
                    "annotations": {
                        "kubernetes.io/ingress.class": "nginx",
                        "nginx.ingress.kubernetes.io/auth-tls-secret": "monitoringv2/ca-secret",
                        "nginx.ingress.kubernetes.io/auth-tls-verify-client": "On",
                        "nginx.ingress.kubernetes.io/backend-protocol": "GRPC",
                        "nginx.ingress.kubernetes.io/grpc-backend": "true",
                        "nginx.ingress.kubernetes.io/http2-listener": "true"
                    },
                    "hosts": ["aks1.prometheus.example.org"],
                    "paths": ["/"],
                    "pathType": "ImplementationSpecific",
                    "tls": [
                        {
                            "secretName": "thanos-ingress-secret",
                            "hosts": ["aks1.prometheus.example.org"]
                        }
                    ]
                },
                "ingress": {
                    "enabled": false
                },
                "additionalServiceMonitors": [
                    {
                        "name": "sm-fluent-bit",
                        "selector": {
                            "matchLabels": {
                                "app.kubernetes.io/instance": "cloud-fluent-bit",
                                "app.kubernetes.io/name": "fluent-bit"
                            }
                        },
                        "namespaceSelector": {
                            "any": true
                        },
                        "endpoints": [
                            {
                                "port": "http",
                                "interval": "10s",
                                "scrapeTimeout": "10s",
                                "path": "/api/v1/metrics/prometheus"
                            }
                        ]
                    },
                    {
                        "name": "sm-ingress-nginx",
                        "selector": {
                            "matchLabels": {
                                "app.kubernetes.io/instance": "cloud-ingress",
                                "app.kubernetes.io/name": "ingress-nginx",
                                "app.kubernetes.io/component": "controller"
                            }
                        },
                        "namespaceSelector": {
                            "any": true
                        },
                        "endpoints": [
                            {
                                "port": "metrics",
                                "interval": "30s"
                            }
                        ]
                    },
                    {
                        "name": "sm-ory-hydra",
                        "selector": {
                            "matchLabels": {
                                "app.kubernetes.io/instance": "iam",
                                "app.kubernetes.io/name": "hydra",
                                "port": "admin"
                            }
                        },
                        "namespaceSelector": {
                            "any": true
                        },
                        "endpoints": [
                            {
                                "port": "http",
                                "interval": "60s",
                                "path": "/metrics/prometheus"
                            }
                        ]
                    },
                    {
                        "name": "sm-redis",
                        "selector": {
                            "matchLabels": {
                                "service": "redis",
                                "port": "exporter",
                                "monitor": "redis-exporter"
                            }
                        },
                        "namespaceSelector": {
                            "any": true
                        },
                        "endpoints": [
                            {
                                "port": "exporter",
                                "interval": "60s"
                            }
                        ]
                    }
                ]
            }
        }
    }

    # Target AKS cluster information
    aks = {
        "aks1": {
            "is_enabled": #{aks1-is-enabled-for-deploy},
            "aks_cluster_name": "aks1",
            "aks_resource_group_name": "aks1"
        }
    }

}
