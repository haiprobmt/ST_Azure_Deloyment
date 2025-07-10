variable location {
  type = string
}

variable resource_group_name {
  type = string
}

variable vnet_cidr {
  type = list(string)
}

variable tags {
  type = map(string)
}

variable vnet_name {
  type = string
}

variable ac_01_cidr {
  type = list(string)
}

variable ac_02_cidr {
  type = list(string)
}

variable ac_03_cidr {
  type = list(string)
}

variable ap_01_cidr {
  type = list(string)
}

variable sa_01_cidr {
  type = list(string)
}

# variable sa_ac_02_cidr {
#   type = list(string)
# }

variable ddos_protection_plan_id {
  type = string
}