# # Backup Recovery Services Vault
# resource "azurerm_recovery_services_vault" "backup_vault" {
#   name                = "backup-vault-lta-bmms-uat-01"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku                 = "Standard" # Options: Standard, RS0
#   soft_delete_enabled = true       # Recommended for compliance
#   tags                = var.tags
# }

data "azurerm_recovery_services_vault" "existing_backup_vault" {
  name                = "backup-vault-lta-bmms-uat-01"
  resource_group_name = "rgrp-lta-bmms-uat-04"
}

# Backup Policy
resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = "backup-policy-lta-bmms-uat-01"
  resource_group_name = "rgrp-lta-bmms-uat-04"
  recovery_vault_name = data.azurerm_recovery_services_vault.existing_backup_vault.name

  # Retention policy
  retention_daily {
    count = 30 # Keep daily backups for 30 days
  }

  backup {
    frequency = "Daily"
    time      = "02:00" # Backup at 2 AM
  }
}
