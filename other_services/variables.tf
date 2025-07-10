variable "location" {
  type = string
#   default = "eastus"
}

variable "law_rg_name" {    
  type = string
}

variable "acr_rg_name" {    
  type = string
}

variable "fa_rg_name" {    
  type = string
}

variable "kv_rg_name" {    
  type = string
}

variable "ddos_rg_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

# variable "object_id" {
#   type = string
#   default = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }

variable "function_app_subnet_id" {
  type = string
}

variable "sa_function_app_subnet_id" {
  type = string
}

variable "analytics_workspace_name" {
  type = string
}

variable "diagnostic_setting_name" {
  type = string
}

variable "container_registry_name" {
  type = string
}

variable "function_app_storage_account_name" {
  type = string
}

variable "app_service_plan_name" {
  type = string
}

variable "function_app_python_name" {
  type = string
}

# variable "function_app_java_name" {
#   type = string
# }

variable "key_vault_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "kv_subnet_id" {
  type = string
}