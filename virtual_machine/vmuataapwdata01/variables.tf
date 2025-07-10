variable location {
  type = string
}

variable resource_group_name {
  type = string
}

variable resource_group_name_common {
  type = string
}

variable tags {
  type = map(string)
}

variable vnet_name {
  type = string
}

variable vm_name {
  type = string
}

variable "subnet_uat_ac_03" {
  type = string
}

variable "data_collection_rule_windows_id" {
  type = string
}

# variable "recovery_vault_name" {
#   type = string
# }

# variable "backup_policy_id" {
#   type = string
# }

variable "log_analytics_workspace_id" {
  type = string
}