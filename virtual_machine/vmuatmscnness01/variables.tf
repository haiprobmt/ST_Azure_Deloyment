variable location {
  type = string
}

variable resource_group_name {
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

variable uat_ness_01_cidr {
  type = list(string)
}

variable "data_collection_rule_linux_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

# variable "recovery_vault_name" {
#   type = string
# }

# variable "backup_policy_id" {
#   type = string
# }