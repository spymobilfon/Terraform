terraform {
    source = "${get_terragrunt_dir()}/../../../modules//cloud_service"
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

remote_state {
    backend = "s3"
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        bucket           = "terraform-backend"
        key              = "prometheus/msteams/local/stand/${file("${get_terragrunt_dir()}/../../../.local/environment_id.txt")}/terraform.tfstate"
        region           = "eu-north-1"
        encrypt          = true
        sse_customer_key = file("${get_terragrunt_dir()}/../../../.local/backend_encryption_key.txt")
    }
}

generate "provider_azurerm" {
    path      = "provider_azurerm.tf"
    if_exists = "overwrite"
    contents = <<EOF
provider "azurerm" {
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
    features {}
}
terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "2.88.1"
        }
    }
}
EOF
}
