terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.88.1"
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
  custom_name = var.custom_name != "" ? var.custom_name : "${random_pet.prefix.id}-db-postgresql"
}

resource "azurerm_resource_group" "main" {
  name     = "${local.custom_name}-rg"
  location = var.location

  lifecycle {
    prevent_destroy = false # https://github.com/hashicorp/terraform/issues/22544
    ignore_changes = [
      name,
      location,
      tags
    ]
  }

  tags     = var.custom_tags
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = local.custom_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  administrator_login    = var.pg_login
  administrator_password = var.pg_password
  backup_retention_days  = var.pg_backup_retention_days
  sku_name               = var.pg_sku_name
  storage_mb             = var.pg_storage_mb
  version                = var.pg_version

  lifecycle {
    prevent_destroy = false # https://github.com/hashicorp/terraform/issues/22544
    ignore_changes = [
      name,
      resource_group_name,
      location,
      administrator_login,
      administrator_password,
      backup_retention_days,
      sku_name,
      storage_mb,
      version,
      tags
    ]
  }

  tags = var.custom_tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  for_each  = toset(var.db_name)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "main" {
  for_each = var.firewall_rules

  name             = each.value["name"]
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value["start_ip_address"]
  end_ip_address   = each.value["end_ip_address"]
}
