variable "preexisting_network" {
  type        = bool
  description = "This value determines if a vnet already exists or not. If true, then will not create a new vnet, subnet, or nsg's"
  default     = false
}

variable "network_resource_group_name" {
  type        = string
  description = "This is the name of the network resource group for new or existing network resources"
}

variable "virtual_network_name" {
  type        = string
  description = "This is the name of the virtual network, new or existing"
}

variable "master_subnet" {
  type        = string
  description = "This is the name of the subnet used for the control plane, new or existing"
}

variable "worker_subnet" {
  type        = string
  description = "This is the name of the subnet used for the compute nodes, new or existing"
}


variable "master_subnet_cidrs" {
  type        = list(string)
  description = "This is the cidr block for the master subnet"
}

variable "worker_subnet_cidrs" {
  type        = list(string)
  description = "This is the cidr block for the worker subnet"
}

variable "vnet_cidr" {
  type        = list(string)
  description = "This is the cidr block for the virtual network"
}

variable "location" {
  type        = string
  description = "This is the location of the virtual network"
}