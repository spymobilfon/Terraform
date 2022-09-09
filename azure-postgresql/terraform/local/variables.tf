variable "custom_name" {
    type        = string
    description = "Azure resource custom name"
    default     = ""
}

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
        system = "postgresql"
        service = "service"
    }
}

variable "pg_login" {
    type        = string
    description = "PostgreSQL administrator login"
    default     = ""

    sensitive   = true

    validation {
        condition     = length(var.pg_login) > 0
        error_message = "PostgreSQL administrator login don't be empty."
    }
}

variable "pg_password" {
    type        = string
    description = "PostgreSQL administrator password"
    default     = ""

    sensitive   = true

    validation {
        condition     = length(var.pg_password) > 0
        error_message = "PostgreSQL administrator password don't be empty."
    }
}

variable "pg_backup_retention_days" {
    type        = number
    description = "PostgreSQL database backup retention days (7-35)"
    default     = 7

    validation {
        condition     = var.pg_backup_retention_days >= 7 && var.pg_backup_retention_days <= 35
        error_message = "PostgreSQL database backup retention days should be between 7 and 35."
    }
}

variable "pg_sku_name" {
    type        = string
    description = "PostgreSQL SKU name"
    default     = "B_Standard_B1ms"
}

variable "pg_storage_mb" {
    type        = number
    description = "PostgreSQL max storage allowed. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216 and 33554432"
    default     = 32768
}

variable "pg_version" {
    type        = string
    description = "PostgreSQL version. Possible values are 11, 12 and 13"
    default     = "13"
}

variable "db_name" {
    type        = list(string)
    description = "The list of PostgreSQL database"
    default     = ["dev", "qa", "demo", "beta"]
}

variable "firewall_rules" {
    description = "PostgreSQL firewall rules"
    type = map(object({
        name             = string
        start_ip_address = string
        end_ip_address   = string
    }))
}
