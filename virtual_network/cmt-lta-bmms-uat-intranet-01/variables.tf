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

variable intranet_ifw_01_cidr {
  type = list(string)
}

variable intranet_efw_01_cidr {
  type = list(string)
}

variable intranet_gw_01_cidr {
  type = list(string)
}