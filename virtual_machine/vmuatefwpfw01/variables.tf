variable location {
  type = string
}

variable resource_group_name {
  type = string
}

variable tags {
  type = map(string)
}

variable route_table_tags {
  type = map(string)
}

variable vnet_name {
  type = string
}

variable vm_name {
  type = string
}

variable internet_ifw_01_cidr {
  type = list(string)
}

variable internet_efw_01_cidr {
  type = list(string)
}

# variable "data_collection_rule_palo_alto_id" {
#   type = string
# }