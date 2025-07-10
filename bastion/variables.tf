variable location {
  type = string
}

variable resource_group_name {
  type = string
}

variable vnet_name {
  type = string
}

variable bastion_cidr {
  type = list(string)
}

variable azure_bastion_service_name {
  type = string
}


variable tags {
  type = map(string)
}