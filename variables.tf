variable "location" {
  type    = string
}

variable "project" {
  type    = string
}

variable "environment" {
  type    = string
}

variable "tenant_id" {
  type    = string
}

variable "subscription_id" {
  type    = string
}

variable "azure_client_id" {
  type        = string
  description = "The app ID that should be used to interact with Azure API"
}

variable "azure_client_secret" {
  type        = string
  description = "The password that should be used to interact with Azure API"
}

variable "cluster_name" {
  type    = string
}

variable "base_domain" {
  type    = string
}

variable "azure_extra_tags" {
  type = map(string)

  description = <<EOF
(optional) Extra Azure tags to be applied to created resources.

Example: `{ "key" = "value", "foo" = "bar" }`
EOF


  default = {}
}

# Resource Groups
variable "rg_uat_01" {
  type        = string
  default     = "rgrp-lta-bmms-uat-01"
  description = "UAT - Public Internet"
}
variable "rg_uat_02" {
  type        = string
  default     = "rgrp-lta-bmms-uat-02"
  description = "UAT - Public Intranet"
}
variable "rg_uat_03" {
  type        = string
  default     = "rgrp-lta-bmms-uat-03"
  description = "UAT - Private Applications"
}
variable "rg_uat_04" {
  type        = string
  default     = "rgrp-lta-bmms-uat-04-temp"
  description = "UAT - Common Services & Bastion"
}
variable "rg_uat_05" {
  type        = string
  default     = "rgrp-lta-bmms-uat-05"
  description = "UAT - Openshift"
}

# Vnets CIDR
variable "uat_01_cidr" {
  type        = list(string)
  default     = ["172.16.0.0/25"]
  description = "UAT - Public Internet"
}
variable "uat_02_cidr" {
  type        = list(string)
  default     = ["172.16.1.0/25"]
  description = "UAT - Public Intranet"
}
variable "uat_03_cidr" {
  type        = list(string)
  default     = ["172.16.2.0/24", "10.0.0.0/16"]
  description = "UAT - Private Applications"
}
variable "uat_04_commonservice_cidr" {
  type        = list(string)
  default     = ["172.16.3.0/24"]
  description = "UAT - Common Services"
}
variable "uat_04_bastion_cidr" {
  type        = list(string)
  default     = ["172.16.4.0/26"]
  description = "UAT - Bastion"
}
# variable "uat_05" {
#   type = list(string)
#   default = [ "172.16.5.0/24" ]
#   description = "UAT - SLS"
# }

# Subnets
variable "internet_ifw_01_cidr" {
  type    = list(string)
  default = ["172.16.0.0/28"]
}
variable "internet_efw_01_cidr" {
  type    = list(string)
  default = ["172.16.0.16/28"]
}
variable "internet_gw_01_cidr" {
  type    = list(string)
  default = ["172.16.0.64/26"]
}
variable "internet_public_01_cidr" {
  type    = list(string)
  default = ["172.16.0.32/28"]
}
variable "intranet_ifw_01_cidr" {
  type    = list(string)
  default = ["172.16.1.0/28"]
}
variable "intranet_efw_01_cidr" {
  type    = list(string)
  default = ["172.16.1.16/28"]
}
variable "intranet_gw_01_cidr" {
  type    = list(string)
  default = ["172.16.1.64/26"]
}
variable "ap_01_cidr" {
  type    = list(string)
  default = ["10.0.0.64/26"]
}
variable "ac_01_cidr" {
  type    = list(string)
  default = ["10.0.0.128/26"]
}
variable "ac_02_cidr" {
  type    = list(string)
  default = ["172.16.2.128/27"]
}
variable "sa_ac_02_cidr" {
  type    = list(string)
  default = ["172.16.2.0/25"]
}
variable "ac_03_cidr" {
  type    = list(string)
  default = ["172.16.2.160/28"]
}
variable "sa_01_cidr" {
  type    = list(string)
  default = ["172.16.2.176/28"]
}
# variable "machine_01_cidr" {
#   type    = list(string)
#   default = ["10.0.0.100/24"]
# }
variable "uat_co_01_cidr" {
  type    = list(string)
  default = ["172.16.3.32/28"]
}
variable "uat_sec_01_cidr" {
  type    = list(string)
  default = ["172.16.3.16/28"]
}
variable "uat_pm_01_cidr" {
  type    = list(string)
  default = ["172.16.3.64/26"]
}
variable "uat_id_01_cidr" {
  type    = list(string)
  default = ["172.16.3.48/28"]
}
variable "uat_ness_01_cidr" {
  type    = list(string)
  default = ["172.16.3.160/28"]
}

variable "uat_bastion_cidr" {
  type    = list(string)
  default = ["172.16.4.32/28"]
}

variable "openshift_ssh_key" {
  description = "SSH Public Key to use for OpenShift Installation"
  type        = string
  default     = ""
}

variable "openshift_byo_dns" {
  description = "Do not deploy any public or private DNS zone into Azure"
  type        = bool
  default     = false
}

variable "azure_preexisting_network" {
  type        = bool
  default     = false
  description = "Specifies whether an existing network should be used or a new one created for installation."
}

variable "pull_secret" {
  type = string
}

variable "airgapped" {
  type = map(string)
  default = {
    enabled    = true
    repository = ""
  }
}

variable "proxy_config" {
  type = map(string)
}

variable "azure_control_plane_subnet" {
  type        = string
  description = "The name of the subnet for the control plane, either existing or to be created."
  default     = null
}

variable "azure_compute_subnet" {
  type        = string
  description = "The name of the subnet for worker nodes, either existing or to be created"
  default     = null
}

variable "azure_private" {
  type        = bool
  description = "This determines if this is a private cluster or not."
  default     = false
}

variable "azure_emulate_single_stack_ipv6" {
  type        = bool
  description = "This determines whether a dual-stack cluster is configured to emulate single-stack IPv6."
  default     = false
}

variable "azure_outbound_user_defined_routing" {
  type    = bool
  default = false

  description = <<EOF
This determined whether User defined routing will be used for egress to Internet.
When false, Standard LB will be used for egress to the Internet.
EOF
}

variable "use_ipv4" {
  type    = bool
  default = true
}

variable "use_ipv6" {
  type    = bool
  default = false
}

variable "openshift_version" {
  type    = string
  default = "4.7.12"
}

variable "master_count" {
  type    = string
  default = 3
  validation {
    condition     = var.master_count == "3"
    error_message = "The master_count value must be set to 3."
  }
}

variable "worker_count" {
  type    = string
  default = 3
  validation {
    condition     = var.worker_count > 1
    error_message = "The worker_count value must be greater than 1."
  }
}

variable "machine_cidr" {
  type = list(string)
  default = ["10.0.0.0/16"]
}

variable "openshift_cluster_network_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "openshift_cluster_network_host_prefix" {
  type    = string
  default = 23
}

variable "openshift_service_network_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "azure_master_availability_zones" {
  type        = list(string)
  description = "The availability zones in which to create the masters. The length of this list must match master_count."
  default = [
    "1",
    "2",
    "3",
  ]
  validation {
    condition     = length(var.azure_master_availability_zones) == 1 || length(var.azure_master_availability_zones) == 3
    error_message = "The azure_master_availability_zones variable must be set to either [1] or [1, 2, 3] zones."
  }
}

variable "azure_worker_vm_type" {
  type    = string
  default = "Standard_D4s_v3"
  # default    = "Standard_B1ms"
}

variable "azure_master_vm_type" {
  type        = string
  description = "Instance type for the master node(s). Example: `Standard_D8s_v3`."
  default     = "Standard_D4s_v3"
  # default    = "Standard_B1ms"
}

variable "azure_worker_root_volume_size" {
  type    = string
  default = 128
}

variable "azure_master_root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device of master nodes."
  default     = 512
}

variable "openshift_additional_trust_bundle" {
  description = "path to a file with all your additional ca certificates"
  type        = string
  default     = ""
}

variable "azure_bootstrap_vm_type" {
  type        = string
  description = "Instance type for the bootstrap node. Example: `Standard_DS4_v3`."
  default     = "Standard_D4s_v3"
  # default    = "Standard_B1ms"
}

variable "azure_master_root_volume_type" {
  type        = string
  description = "The type of the volume the root block device of master nodes."
  default     = "Standard_LRS"
}