variable vnet_name {    
  type = string
}

variable location {
  type = string
}

variable resource_group_name {
  type = string
}

variable internet_gw_01_cidr {
  type = list(string)
}

variable tags {
  type = map(string)
}

variable ddos_protection_plan_id {
  type = string
}