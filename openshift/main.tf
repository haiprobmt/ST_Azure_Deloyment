terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}
provider "azurerm" {
  features {}
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

resource "random_string" "cluster_id" {
  length  = 5
  special = false
  upper   = false
}

# SSH Key for VMs
resource "tls_private_key" "installkey" {
  count     = var.openshift_ssh_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_private_key" {
  count           = var.openshift_ssh_key == "" ? 1 : 0
  content         = tls_private_key.installkey[0].private_key_pem
  filename        = "${path.root}/installer-files/artifacts/openshift_rsa"
  file_permission = 0600
}

resource "local_file" "write_public_key" {
  content         = local.public_ssh_key
  filename        = "${path.root}/installer-files/artifacts/openshift_rsa.pub"
  file_permission = 0600
}


data "template_file" "azure_sp_json" {
  template = <<EOF
{
  "subscriptionId":"${var.azure_subscription_id}",
  "clientId":"${var.azure_client_id}",
  "clientSecret":"${var.azure_client_secret}",
  "tenantId":"${var.azure_tenant_id}"
}
EOF
}

resource "local_file" "azure_sp_json" {
  content  = data.template_file.azure_sp_json.rendered
  filename = pathexpand("~/.azure/osServicePrincipal.json")
}

# data "http" "images" {
#   url = "https://raw.githubusercontent.com/openshift/installer/release-${local.major_version}/data/data/rhcos.json"
#   request_headers = {
#     Accept = "application/json"
#   }
# }

locals {
  image_workspace     = "${path.root}/image-files/"
}

resource "null_resource" "download_image_vhd" {
  provisioner "local-exec" {
    command = templatefile("./ignition/scripts/download_image_vhd.sh.tmpl", {
      installer_url = "https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.14/latest/rhcos-4.14.34-x86_64-azure.x86_64.vhd.gz"
    })
  }
}

locals {
  cluster_id = "${var.cluster_name}-${random_string.cluster_id.result}"
  tags = merge(
    {
      "kubernetes.io_cluster.${local.cluster_id}" = "owned"
    },
    var.azure_extra_tags,
  )
  azure_network_resource_group_name = "rgrp-lta-bmms-uat-03"
  azure_virtual_network             = "cmt-lta-bmms-uat-application-01"
  azure_control_plane_subnet        = "snet-lta-bmms-uat-ac-01"
  azure_compute_subnet              = "snet-lta-bmms-uat-ac-02"
  public_ssh_key                    = var.openshift_ssh_key == "" ? tls_private_key.installkey[0].public_key_openssh : file(var.openshift_ssh_key)
  major_version                     = join(".", slice(split(".", var.openshift_version), 0, 2))
  # rhcos_image                       = lookup(lookup(jsondecode(data.http.images.body), "azure"), "url")
}

module "vnet" {
  source              = "./vnet"
  master_subnet_cidrs = var.master_subnet_cidrs
  worker_subnet_cidrs = var.worker_subnet_cidrs
  preexisting_network         = var.azure_preexisting_network
  virtual_network_name          = local.azure_virtual_network
  network_resource_group_name   = local.azure_network_resource_group_name
  master_subnet               = local.azure_control_plane_subnet
  worker_subnet               = local.azure_compute_subnet
  vnet_cidr                   = var.vnet_cidr
  location                    = var.azure_region
  depends_on                  = [azurerm_resource_group.network]
  }

# data "azurerm_virtual_network" "cluster_vnet" {
#   name                = local.azure_virtual_network
#   resource_group_name = local.azure_network_resource_group_name
# }

# data "azurerm_subnet" "master_subnet" {
#   name                 = local.azure_control_plane_subnet
#   virtual_network_name = local.azure_virtual_network
#   resource_group_name  = local.azure_network_resource_group_name
# }

# data "azurerm_subnet" "worker_subnet" {
#   name                 = local.azure_compute_subnet
#   virtual_network_name = local.azure_virtual_network
#   resource_group_name  = local.azure_network_resource_group_name
# }

module "network" {
  source              = "./network"
  resource_group_name = azurerm_resource_group.main.name
  vnet_v4_cidrs       = var.machine_v4_cidrs
  vnet_v6_cidrs       = var.machine_v6_cidrs
  cluster_id          = local.cluster_id
  region              = var.azure_region
  dns_label           = local.cluster_id

  preexisting_network         = var.azure_preexisting_network
  network_resource_group_name = local.azure_network_resource_group_name
  virtual_network_name        = local.azure_virtual_network
  master_subnet               = module.vnet.master_subnet
  worker_subnet               = module.vnet.worker_subnet
  private                     = var.azure_private
  outbound_udr                = var.azure_outbound_user_defined_routing
  master_subnet_id            = module.vnet.master_subnet_id
  worker_subnet_id            = module.vnet.worker_subnet_id
  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  base_domain               = var.base_domain
  environment               = var.azure_environment
  project                   = var.azure_project
  depends_on                = [module.vnet, azurerm_resource_group.main]
}

module "ignition" {
  source                        = "./ignition"
  depends_on                    = [local_file.azure_sp_json, module.network]
  base_domain                   = var.base_domain
  openshift_version             = var.openshift_version
  master_count                  = var.master_count
  cluster_name                  = var.cluster_name
  cluster_network_cidr          = var.openshift_cluster_network_cidr
  cluster_network_host_prefix   = var.openshift_cluster_network_host_prefix
  machine_cidr                  = var.machine_v4_cidrs[0]
  service_network_cidr          = var.openshift_service_network_cidr
  azure_dns_resource_group_name = var.azure_base_domain_resource_group_name
  openshift_pull_secret         = var.openshift_pull_secret
  public_ssh_key                = chomp(local.public_ssh_key)
  cluster_id                    = local.cluster_id
  resource_group_name           = azurerm_resource_group.main.name
  availability_zones            = var.azure_master_availability_zones
  node_count                    = var.worker_count
  infra_count                   = var.infra_count
  azure_region                  = var.azure_region
  worker_vm_type                = var.azure_worker_vm_type
  infra_vm_type                 = var.azure_infra_vm_type
  master_vm_type                = var.azure_master_vm_type
  worker_os_disk_size           = var.azure_worker_root_volume_size
  infra_os_disk_size            = var.azure_infra_root_volume_size
  master_os_disk_size           = var.azure_master_root_volume_size
  azure_subscription_id         = var.azure_subscription_id
  azure_client_id               = var.azure_client_id
  azure_client_secret           = var.azure_client_secret
  azure_tenant_id               = var.azure_tenant_id
  # azure_rhcos_image_id          = azurerm_image.cluster.id
  virtual_network_name          = local.azure_virtual_network
  network_resource_group_name   = local.azure_network_resource_group_name
  control_plane_subnet          = local.azure_control_plane_subnet
  compute_subnet                = local.azure_compute_subnet
  private                       = module.network.private
  outbound_udr                  = var.azure_outbound_user_defined_routing
  airgapped                     = var.airgapped
  proxy_config                  = var.proxy_config
  trust_bundle                  = var.openshift_additional_trust_bundle
  byo_dns                       = var.openshift_byo_dns
  environment               = var.azure_environment
  project                   = var.azure_project
}

module "bootstrap" {
  source                 = "./bootstrap"
  resource_group_name    = azurerm_resource_group.main.name
  region                 = var.azure_region
  vm_size                = var.azure_bootstrap_vm_type
  vm_image               = azurerm_image.cluster.id
  identity               = azurerm_user_assigned_identity.main.id
  cluster_id             = local.cluster_id
  bootstrap_ignition_url_sas  = module.ignition.bootstrap_ignition_url_sas
  subnet_id              = module.vnet.master_subnet_id
  elb_backend_pool_v4_id = module.network.public_lb_backend_pool_v4_id
  elb_backend_pool_v6_id = module.network.public_lb_backend_pool_v6_id
  ilb_backend_pool_v4_id = module.network.internal_lb_backend_pool_v4_id
  ilb_backend_pool_v6_id = module.network.internal_lb_backend_pool_v6_id
  tags                   = local.tags
  storage_account        = azurerm_storage_account.cluster
  nsg_name               = module.network.cluster_nsg_name
  private                = module.network.private
  outbound_udr           = var.azure_outbound_user_defined_routing

  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  depends_on                = [module.ignition]
}

module "master" {
  source                 = "./master"
  resource_group_name    = azurerm_resource_group.main.name
  cluster_id             = local.cluster_id
  region                 = var.azure_region
  availability_zones     = var.azure_master_availability_zones
  vm_size                = var.azure_master_vm_type
  vm_image               = azurerm_image.cluster.id
  identity               = azurerm_user_assigned_identity.main.id
  master_ignition_url_sas   = module.ignition.master_ignition_url_sas
  elb_backend_pool_v4_id = module.network.public_lb_backend_pool_v4_id
  elb_backend_pool_v6_id = module.network.public_lb_backend_pool_v6_id
  ilb_backend_pool_v4_id = module.network.internal_lb_backend_pool_v4_id
  ilb_backend_pool_v6_id = module.network.internal_lb_backend_pool_v6_id
  subnet_id              = module.vnet.master_subnet_id
  instance_count         = var.master_count
  storage_account        = azurerm_storage_account.cluster
  os_volume_type         = var.azure_master_root_volume_type
  os_volume_size         = var.azure_master_root_volume_size
  private                = module.network.private
  outbound_udr           = var.azure_outbound_user_defined_routing

  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  environment               = var.azure_environment
  project                   = var.azure_project 
  depends_on                = [module.bootstrap]
}


module "dns" {
  count                           = var.openshift_byo_dns ? 0 : 1
  source                          = "./dns"
  cluster_domain                  = "${var.cluster_name}.${var.base_domain}"
  cluster_id                      = local.cluster_id
  base_domain                     = var.base_domain
  virtual_network_id              = module.vnet.virtual_network_id
  external_lb_fqdn_v4             = module.network.public_lb_pip_v4_fqdn
  external_lb_fqdn_v6             = module.network.public_lb_pip_v6_fqdn
  internal_lb_ipaddress_v4        = module.network.internal_lb_ip_v4_address
  internal_lb_ipaddress_v6        = module.network.internal_lb_ip_v6_address
  resource_group_name             = azurerm_resource_group.main.name
  base_domain_resource_group_name = var.azure_base_domain_resource_group_name
  private                         = module.network.private

  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  environment               = var.azure_environment
  project                   = var.azure_project
  depends_on = [azurerm_resource_group.main]
}

resource "azurerm_resource_group" "main" {
  name     = "rgrp-lta-bmms-uat-05"
  location = var.azure_region
  tags     = {
    environment = var.azure_environment
    project = var.azure_project
    purpose = "openshift cluster resource group"
  }
}

resource "azurerm_resource_group" "network" {
  name     = local.azure_network_resource_group_name
  location = var.azure_region
  tags     = {
    environment = var.azure_environment
    project = var.azure_project
    purpose = "application network resource group"
  }
}

data "azurerm_resource_group" "network" {
  count = var.azure_preexisting_network ? 1 : 0

  name = var.azure_network_resource_group_name
}

resource "azurerm_storage_account" "cluster" {
  name                     = "cluster${var.cluster_name}${random_string.cluster_id.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = {
    environment = var.azure_environment
    project = var.azure_project
    purpose = "openshift image storage account"
  }
  depends_on = [azurerm_resource_group.main]
}

resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region

  name = "${local.cluster_id}-identity"
  depends_on = [azurerm_resource_group.main]
}

# resource "azurerm_role_assignment" "main" {
#   scope                = data.azurerm_resource_group.main.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "network" {
#   count = var.azure_preexisting_network ? 1 : 0

#   scope                = data.azurerm_resource_group.network[0].id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# copy over the vhd to cluster resource group and create an image using that
resource "azurerm_storage_container" "vhd" {
  name                 = "vhd"
  storage_account_name = azurerm_storage_account.cluster.name
  depends_on           = [null_resource.download_image_vhd]
}

resource "azurerm_storage_blob" "rhcos_image" {
  name                   = "rhcos${random_string.cluster_id.result}.vhd"
  storage_account_name   = azurerm_storage_account.cluster.name
  storage_container_name = azurerm_storage_container.vhd.name
  type                   = "Page"
  source                 = "${local.image_workspace}/rhcos-4.14.34-x86_64-azure.x86_64.vhd"
}

resource "azurerm_image" "cluster" {
  name                = local.cluster_id
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    storage_type = "Standard_LRS"
    blob_uri = azurerm_storage_blob.rhcos_image.url
  }
}

# resource "null_resource" "delete_bootstrap" {
#   depends_on = [
#     module.master
#   ]

#   provisioner "local-exec" {
#     command = <<EOF
# ./installer-files/openshift-install --dir=./installer-files wait-for bootstrap-complete --log-level=debug
# az vm delete -g ${azurerm_resource_group.main.name} -n ${local.cluster_id}-bootstrap -y
# az disk delete -g ${azurerm_resource_group.main.name} -n ${local.cluster_id}-bootstrap_OSDisk -y
# if [[ "${var.azure_private}" == "false" ]]; then
#   az network nic ip-config update -g ${azurerm_resource_group.main.name} -n bootstrap-nic-ip-v4 --nic-name ${local.cluster_id}-bootstrap-nic --remove PublicIpAddress
#   az network public-ip delete -g ${azurerm_resource_group.main.name} -n ${local.cluster_id}-bootstrap-pip-v4
# fi
# az network nic delete -g ${azurerm_resource_group.main.name} -n ${local.cluster_id}-bootstrap-nic
# EOF    
#   }
# }
