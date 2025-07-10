resource "azurerm_resource_group" "uat_01" {
  name     = var.rg_uat_01
  location = var.location
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Internet Compartment"
  }
  # description = "Resource Group for public internet compartment"
}

resource "azurerm_resource_group" "uat_02" {
  name     = var.rg_uat_02
  location = var.location
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Intranet Compartment"
  }
  # description = "Resource Group for public intranet compartment"
}

resource "azurerm_resource_group" "uat_03" {
  name     = var.rg_uat_03
  location = var.location
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Application Compartment"
  }
  # description = "Resource Group for application compartment"
}

resource "azurerm_resource_group" "uat_04_common" {
  name     = var.rg_uat_04
  location = var.location
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Common Services Compartment"
  }
  # description = "Resource Group for common service compartment and Azure services related to infra"
}

resource "azurerm_resource_group" "uat_05_openshift" {

  name     = var.rg_uat_05
  location = var.location
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Openshift Resource Group"
  }
  depends_on = [ azurerm_resource_group.uat_03, module.network_uat_application_01 ]
}


module "network_uat_common_01" {
  source              = "./virtual_network/cmt-lta-bmms-uat-common-01"
  vnet_name           = "cmt-lta-bmms-uat-common-01"
  location            = var.location
  resource_group_name = var.rg_uat_04
  vnet_cidr           = var.uat_04_commonservice_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "UAT - Common Service"
  }
  depends_on = [azurerm_resource_group.uat_04_common]
  # description = "Resource Group for common service compartment and Azure services related to infra"
}

module "network_uat_intranet_01" {
  source               = "./virtual_network/cmt-lta-bmms-uat-intranet-01"
  vnet_name            = "cmt-lta-bmms-uat-intranet-01"
  location             = var.location
  resource_group_name  = var.rg_uat_02
  vnet_cidr            = var.uat_02_cidr
  intranet_ifw_01_cidr = var.intranet_ifw_01_cidr
  intranet_efw_01_cidr = var.intranet_efw_01_cidr
  intranet_gw_01_cidr  = var.intranet_gw_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "UAT - Public Intranet"
  }
  depends_on = [azurerm_resource_group.uat_02]
}

module "network_uat_application_01" {
  source              = "./virtual_network/cmt-lta-bmms-uat-application-01"
  vnet_name           = "cmt-lta-bmms-uat-application-01"
  location            = var.location
  resource_group_name = var.rg_uat_03
  vnet_cidr           = var.uat_03_cidr
  ac_01_cidr          = var.ac_01_cidr
  ac_02_cidr          = var.ac_02_cidr
  ac_03_cidr          = var.ac_03_cidr
  ap_01_cidr          = var.ap_01_cidr
  sa_01_cidr          = var.sa_01_cidr
  # sa_ac_02_cidr       = var.sa_01_cidr
  ddos_protection_plan_id = module.network_uat_internet_01.ddos_protection_plan_id
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "UAT - Private Application"
  }
  depends_on = [azurerm_resource_group.uat_03]
}

module "network_uat_internet_01" {
  source                  = "./virtual_network/cmt-lta-bmms-uat-internet-01"
  vnet_name               = "cmt-lta-bmms-uat-internet-01"
  location                = var.location
  resource_group_name     = var.rg_uat_01
  vnet_cidr               = var.uat_01_cidr
  internet_gw_01_cidr     = var.internet_gw_01_cidr
  internet_public_01_cidr = var.internet_public_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "UAT - Public Internet"
  }
  depends_on = [azurerm_resource_group.uat_01]
}

module "network_uat_bastion_01" {
  source              = "./virtual_network/cmt-lta-bmms-uat-bastion-01"
  vnet_name           = "cmt-lta-bmms-uat-bastion-01"
  location            = var.location
  resource_group_name = var.rg_uat_04
  vnet_cidr           = var.uat_04_bastion_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "UAT - Bastion"
  }
  depends_on = [azurerm_resource_group.uat_04_common]
}

module "application_gateway" {
  source              = "./applicationgateway"
  vnet_name           = module.network_uat_internet_01.vnet_name
  location            = var.location
  resource_group_name = var.rg_uat_01
  internet_gw_01_cidr = var.internet_gw_01_cidr
  ddos_protection_plan_id = module.network_uat_internet_01.ddos_protection_plan_id
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Application Gateway"
  }
  depends_on = [module.network_uat_internet_01]
}

module "backup_vault" {
  source              = "./backup"
  # location            = var.location
  # resource_group_name = var.rg_uat_04
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Backup Vault"
  }
  depends_on = [module.network_uat_common_01]
}

module "vm_tableau_data" {
  source              = "./virtual_machine/vmuataapwdata01"
  vm_name             = "vmuataapwdata01"
  location            = var.location
  resource_group_name = var.rg_uat_03
  resource_group_name_common = var.rg_uat_04
  subnet_uat_ac_03    = module.network_uat_application_01.tableau_subnet_id
  vnet_name           = module.network_uat_application_01.vnet_name
  data_collection_rule_windows_id  = module.other_services.data_collection_rule_windows_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  log_analytics_workspace_id = module.other_services.log_analytics_workspace_id
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Tableau Data Extractor"
  }
  depends_on = [module.network_uat_application_01, module.backup_vault]
}

module "vm_management_console" {
  source              = "./virtual_machine/vmuatmcowcon01"
  vm_name             = "vmuatmcowcon01"
  location            = var.location
  resource_group_name = azurerm_resource_group.uat_04_common.name
  vnet_name           = module.network_uat_common_01.vnet_name
  data_collection_rule_windows_id  = module.other_services.data_collection_rule_windows_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  uat_co_01_cidr      = var.uat_co_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Management & Console Server"
  }
  depends_on = [module.network_uat_common_01, module.backup_vault]
}

module "vm_BMMS_AD" {
  source              = "./virtual_machine/vmuatmidwad01"
  vm_name             = "vmuatmidwad01"
  location            = var.location
  resource_group_name = azurerm_resource_group.uat_04_common.name
  vnet_name           = module.network_uat_common_01.vnet_name
  data_collection_rule_windows_id  = module.other_services.data_collection_rule_windows_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  uat_id_01_cidr      = var.uat_id_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "BMMS AD"
  }
  depends_on = [module.network_uat_common_01, module.backup_vault]
}

module "vm_Wsus" {
  source              = "./virtual_machine/vmuatmpmwwsus01"
  vm_name             = "vmuatmpmwwsus01"
  location            = var.location
  resource_group_name = azurerm_resource_group.uat_04_common.name
  vnet_name           = module.network_uat_common_01.vnet_name
  data_collection_rule_windows_id  = module.other_services.data_collection_rule_windows_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  uat_pm_01_cidr      = var.uat_pm_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "WSUS"
  }
  depends_on = [module.network_uat_common_01, module.backup_vault]
}

module "vm_ABLR" {
  source              = "./virtual_machine/vmuatmscwablr01"
  vm_name             = "vmuatmscwablr01"
  location            = var.location
  resource_group_name = azurerm_resource_group.uat_04_common.name
  vnet_name           = module.network_uat_common_01.vnet_name
  data_collection_rule_windows_id  = module.other_services.data_collection_rule_windows_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  uat_sec_01_cidr     = var.uat_sec_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "ABLR Forwarder"
  }
  depends_on = [module.network_uat_common_01, module.backup_vault]
}

module "vm_Nessus" {
  source              = "./virtual_machine/vmuatmscnness01"
  vm_name             = "vmuatmscnness01"
  location            = var.location
  resource_group_name = azurerm_resource_group.uat_04_common.name
  vnet_name           = module.network_uat_common_01.vnet_name
  data_collection_rule_linux_id  = module.other_services.data_collection_rule_linux_id
  # recovery_vault_name = module.backup_vault.recovery_vault_name
  # backup_policy_id    = module.backup_vault.backup_policy_id
  uat_ness_01_cidr    = var.uat_ness_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Vulnerability & Compliance Scan"
  }
  depends_on = [module.network_uat_common_01, module.backup_vault]
}

module "vm_PaloAlto" {
  source               = "./virtual_machine/vmuatefwpfw01"
  vm_name              = "vmuatefwpfw01"
  location             = var.location
  resource_group_name  = azurerm_resource_group.uat_01.name
  vnet_name            = module.network_uat_internet_01.vnet_name
  # data_collection_rule_palo_alto_id  = module.other_services.data_collection_rule_palo_alto_id
  internet_ifw_01_cidr = var.internet_ifw_01_cidr
  internet_efw_01_cidr = var.internet_efw_01_cidr
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Palo Alto firewall"
  }
  route_table_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Route Table"
  }
  depends_on = [module.network_uat_internet_01]
}

module "Bastion" {
  source                     = "./bastion"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.uat_04_common.name
  vnet_name                  = module.network_uat_bastion_01.vnet_name
  bastion_cidr               = var.uat_bastion_cidr
  azure_bastion_service_name = "uat-bastion-01"
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Bastion Host"
  }
  depends_on = [module.network_uat_bastion_01]
}

module "vnet_peering_internet_to_commonservices" {
  source             = "./vnet_peering/internet_to_commonservices"
  internet_vnet_name = module.network_uat_internet_01.vnet_name
  common_vnet_name   = module.network_uat_common_01.vnet_name
  internet_rg_name   = azurerm_resource_group.uat_01.name
  common_rg_name     = azurerm_resource_group.uat_04_common.name
  depends_on         = [module.network_uat_common_01]
}

module "vnet_peering_intranet_to_application" {
  source                = "./vnet_peering/intranet_to_application"
  intranet_vnet_name    = module.network_uat_intranet_01.vnet_name
  application_vnet_name = module.network_uat_application_01.vnet_name
  intranet_rg_name      = azurerm_resource_group.uat_02.name
  application_rg_name   = azurerm_resource_group.uat_03.name
  depends_on            = [module.network_uat_intranet_01, module.network_uat_application_01]
}

module "vnet_peering_internet_application" {
  source                = "./vnet_peering/internet_to_application"
  internet_vnet_name    = module.network_uat_internet_01.vnet_name
  application_vnet_name = module.network_uat_application_01.vnet_name
  internet_rg_name      = azurerm_resource_group.uat_01.name
  application_rg_name   = azurerm_resource_group.uat_03.name
  depends_on            = [module.network_uat_application_01]
}

module "vnet_peering_application_commonservices" {
  source                = "./vnet_peering/application_to_commonservices"
  application_vnet_name = module.network_uat_application_01.vnet_name
  common_vnet_name      = module.network_uat_common_01.vnet_name
  application_rg_name   = azurerm_resource_group.uat_03.name
  common_rg_name        = azurerm_resource_group.uat_04_common.name
  depends_on            = [module.network_uat_application_01, module.network_uat_common_01]
}

module "vnet_peering_intranet_commonservices" {
  source             = "./vnet_peering/intranet_to_commonservices"
  intranet_vnet_name = module.network_uat_intranet_01.vnet_name
  common_vnet_name   = module.network_uat_common_01.vnet_name
  intranet_rg_name   = azurerm_resource_group.uat_02.name
  common_rg_name     = azurerm_resource_group.uat_04_common.name
  depends_on         = [module.network_uat_intranet_01, module.network_uat_common_01]
}

module "vnet_peering_bastion_commonservices" {
  source             = "./vnet_peering/bastion_to_commonservices"
  bastion_vnet_name = module.network_uat_bastion_01.vnet_name
  common_vnet_name   = module.network_uat_common_01.vnet_name
  common_rg_name     = azurerm_resource_group.uat_04_common.name
  depends_on         = [module.network_uat_bastion_01, module.network_uat_common_01]
}

module "other_services" {
  source       = "./other_services"
  location     = var.location
  # apim_rg_name = var.rg_uat_03
  law_rg_name  = var.rg_uat_04
  fa_rg_name   = var.rg_uat_03
  kv_rg_name   = var.rg_uat_04
  acr_rg_name  = var.rg_uat_05
  ddos_rg_name = var.rg_uat_01
  tenant_id    = var.tenant_id
  function_app_subnet_id = module.network_uat_application_01.function_app_subnet_id
  sa_function_app_subnet_id = module.network_uat_application_01.storage_account_subnet_id
  analytics_workspace_name = "law-lta-bmms-uat-${local.cluster_id}"
  diagnostic_setting_name = "ds-lta-bmms-uat-${local.cluster_id}"
  container_registry_name = "acrltabmmsuat${var.cluster_name}${random_string.cluster_id.result}"
  function_app_storage_account_name = "safaltabmmsuat${var.cluster_name}${random_string.cluster_id.result}"
  app_service_plan_name = "asp-lta-bmms-uat-${local.cluster_id}"
  function_app_python_name = "fapython-lta-bmms-uat-${local.cluster_id}"
  # function_app_java_name = "fajava-lta-bmms-uat-${local.cluster_id}"
  key_vault_name = "kvltabmmsuat${var.cluster_name}${random_string.cluster_id.result}"
  kv_subnet_id   = module.network_uat_application_01.kv_subnet_id
  vnet_id        = module.network_uat_application_01.vnet_id
  vnet_name      = module.network_uat_application_01.vnet_name 
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Other Services"
  }
  depends_on = [module.network_uat_application_01, azurerm_resource_group.uat_01, azurerm_resource_group.uat_02, azurerm_resource_group.uat_03, azurerm_resource_group.uat_04_common, azurerm_resource_group.uat_05_openshift]
}

## Openshift Creation

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
  filename        = "${path.root}/openshift/artifacts/openshift_rsa"
  file_permission = 0600
}

resource "local_file" "write_public_key" {
  content         = local.public_ssh_key
  filename        = "${path.root}/openshift/artifacts/openshift_rsa.pub"
  file_permission = 0600
}


data "template_file" "azure_sp_json" {
  template = <<EOF
{
  "subscriptionId":"${var.subscription_id}",
  "clientId": "${var.azure_client_id}",
  "clientSecret":"${var.azure_client_secret}",
  "tenantId":"${var.tenant_id}"
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
  cluster_id = "${var.cluster_name}-${random_string.cluster_id.result}"
  tags = merge(
    {
      "kubernetes.io_cluster.${local.cluster_id}" = "owned"
    },
    var.azure_extra_tags,
  )
  public_ssh_key = var.openshift_ssh_key == "" ? tls_private_key.installkey[0].public_key_openssh : file(var.openshift_ssh_key)
  rhcos_image    = "https://rhcos.blob.core.windows.net/imagebucket/rhcos-418.94.202410090804-0-azure.x86_64.vhd"
}

locals {
  installer_workspace = "${path.root}/installer-files/"
}


module "ocp_network_config" {
  source                      = "./openshift/network_config"
  resource_group_name         = var.rg_uat_05
  master_subnet_id            = module.network_uat_application_01.master_subnet_id
  worker_subnet_id            = module.network_uat_application_01.worker_subnet_id
  cluster_id                  = local.cluster_id
  region                      = var.location
  dns_label                   = local.cluster_id
  preexisting_network         = var.azure_preexisting_network
  network_resource_group_name = module.network_uat_application_01.vnet_name
  # network_resource_group_id   = module.network_uat_application_01.vnet_id
  virtual_network_name        = module.network_uat_application_01.vnet_name
  master_subnet               = "${local.cluster_id}-master-subnet"
  worker_subnet               = "${local.cluster_id}-worker-subnet"
  private                     = var.azure_private
  outbound_udr                = var.azure_outbound_user_defined_routing
  use_ipv4                    = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  emulate_single_stack_ipv6   = var.azure_emulate_single_stack_ipv6
  depends_on                  = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
  base_domain                 = var.base_domain
  nsg_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "NSG Rules for Nodes"
  }

  dns_global_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "DNS Global Zone"
  }
}

module "ignition" {
  source                        = "./openshift/ignition"
  depends_on                    = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
  base_domain                   = var.base_domain
  openshift_version             = var.openshift_version
  master_count                  = var.master_count
  cluster_name                  = var.cluster_name
  cluster_network_cidr          = var.openshift_cluster_network_cidr
  cluster_network_host_prefix   = var.openshift_cluster_network_host_prefix
  machine_cidr                  = var.machine_cidr[0]
  service_network_cidr          = var.openshift_service_network_cidr
  azure_dns_resource_group_name = var.rg_uat_05
  pull_secret                   = var.pull_secret
  public_ssh_key                = chomp(local.public_ssh_key)
  cluster_id                    = local.cluster_id
  resource_group_name           = var.rg_uat_05
  availability_zones            = var.azure_master_availability_zones
  primary_connection_string     = module.storage_account.storage_account_primary_string
  sa_name                       = module.storage_account.storage_account_name
  node_count                    = var.worker_count
  azure_region_config           = "southeastasia"
  # infra_count                   = var.infra_count
  azure_region   = var.location
  worker_vm_type = var.azure_worker_vm_type
  # infra_vm_type                 = var.azure_infra_vm_type
  master_vm_type      = var.azure_master_vm_type
  worker_os_disk_size = var.azure_worker_root_volume_size
  # infra_os_disk_size            = var.azure_infra_root_volume_size
  master_os_disk_size         = var.azure_master_root_volume_size
  azure_subscription_id       = var.subscription_id
  azure_client_id             = var.azure_client_id
  azure_client_secret         = var.azure_client_secret
  azure_tenant_id             = var.tenant_id
  azure_rhcos_image_id        = azurerm_image.cluster.id
  virtual_network_name        = module.network_uat_application_01.vnet_name
  network_resource_group_name = var.rg_uat_03
  control_plane_subnet        = module.network_uat_application_01.master_subnet
  compute_subnet              = module.network_uat_application_01.worker_subnet
  private                     = module.ocp_network_config.private
  outbound_udr                = var.azure_outbound_user_defined_routing
  airgapped                   = var.airgapped
  proxy_config                = var.proxy_config
  trust_bundle                = var.openshift_additional_trust_bundle
  byo_dns                     = var.openshift_byo_dns
  # storage_account_id          = module.storage_account.storage_account_id
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Ignition Files Storage"
  }
}

module "bootstrap" {
  source                 = "./openshift/bootstrap"
  resource_group_name    = var.rg_uat_05
  region                 = var.location
  vm_size                = var.azure_bootstrap_vm_type
  vm_image               = azurerm_image.cluster.id
  identity               = azurerm_user_assigned_identity.main.id
  cluster_id             = local.cluster_id
  ignition               = module.ignition.bootstrap_ignition
  subnet_id              = module.network_uat_application_01.master_subnet_id
  elb_backend_pool_v4_id = module.ocp_network_config.public_lb_backend_pool_v4_id
  ilb_backend_pool_v4_id = module.ocp_network_config.internal_lb_backend_pool_v4_id
  primary_blob_endpoint  = module.storage_account.primary_blob_endpoint
  nsg_name               = module.ocp_network_config.cluster_nsg_name
  private                = module.ocp_network_config.private
  outbound_udr           = var.azure_outbound_user_defined_routing
  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  nic_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Bootstrap NIC"
  }
  bootstrap_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Bootstrap VM"
  }
  depends_on = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
}

module "master" {
  source                    = "./openshift/master"
  resource_group_name       = var.rg_uat_05
  region                    = var.location
  availability_zones        = var.azure_master_availability_zones
  vm_size                   = var.azure_master_vm_type
  vm_image                  = azurerm_image.cluster.id
  identity                  = azurerm_user_assigned_identity.main.id
  ignition                  = module.ignition.master_ignition
  elb_backend_pool_v4_id    = module.ocp_network_config.public_lb_backend_pool_v4_id
  ilb_backend_pool_v4_id    = module.ocp_network_config.internal_lb_backend_pool_v4_id
  subnet_id                 = module.network_uat_application_01.master_subnet_id
  instance_count            = var.master_count
  primary_blob_endpoint     = module.storage_account.primary_blob_endpoint
  os_volume_type            = var.azure_master_root_volume_type
  os_volume_size            = var.azure_master_root_volume_size
  private                   = module.ocp_network_config.private
  outbound_udr              = var.azure_outbound_user_defined_routing
  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  vm_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Master VM"
  }
  nic_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Master NIC"
  }
  depends_on = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
}

module "dns" {
  count                           = var.openshift_byo_dns ? 0 : 1
  source                          = "./openshift/dns"
  cluster_domain                  = "${var.cluster_name}.${var.base_domain}"
  cluster_id                      = local.cluster_id
  base_domain                     = var.base_domain
  virtual_network_id              = module.network_uat_application_01.vnet_id
  virtual_network_common_id       = module.network_uat_common_01.vnet_id
  external_lb_fqdn_v4             = module.ocp_network_config.public_lb_pip_v4_fqdn
  internal_lb_ipaddress_v4        = module.ocp_network_config.internal_lb_ip_v4_address
  resource_group_name             = var.rg_uat_05
  base_domain_resource_group_name = var.rg_uat_05
  private                         = module.ocp_network_config.private
  use_ipv4                  = var.use_ipv4 || var.azure_emulate_single_stack_ipv6
  use_ipv6                  = var.use_ipv6
  emulate_single_stack_ipv6 = var.azure_emulate_single_stack_ipv6
  dns_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Private Openshift DNS"
  }
  dns_link_tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Private Openshift DNS Link"
  }
  depends_on = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
}

module "storage_account" {
  source                    = "./openshift/storage_account"
  resource_group_name       = var.rg_uat_05
  # application_vnet_name_id  = module.network_uat_application_01.vnet_id
  cluster_id                = local.cluster_id
  location                  = var.location
  project                   = var.project
  environment               = var.environment
  # storage_account_subnet_id = module.network_uat_application_01.storage_account_subnet_id
  depends_on = [local_file.azure_sp_json, module.network_uat_application_01, 
  module.network_uat_common_01, module.network_uat_intranet_01, module.network_uat_internet_01,
  module.network_uat_bastion_01, azurerm_resource_group.uat_05_openshift]
}

resource "azurerm_user_assigned_identity" "main" {
  resource_group_name = azurerm_resource_group.uat_05_openshift.name
  location            = var.location

  name = "${local.cluster_id}-identity"
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Openshift Cluster Idenity"
  }
}

# resource "azurerm_role_assignment" "main" {
#   scope                = azurerm_resource_group.uat_05_openshift.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "network" {
#   count = var.azure_preexisting_network ? 1 : 0

#   scope                = module.network_uat_application_01.vnet_id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }

# resource "azurerm_role_assignment" "blob_access" {
#   scope                = module.storage_account.storage_account_id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.main.principal_id
# }


# copy over the vhd to cluster resource group and create an image using that
resource "azurerm_storage_container" "vhd" {
  name               = "vhd"
  storage_account_id = module.storage_account.storage_account_id
}

resource "azurerm_storage_blob" "rhcos_image" {
  name                   = "rhcos${random_string.cluster_id.result}.vhd"
  storage_account_name   = module.storage_account.storage_account_name
  storage_container_name = azurerm_storage_container.vhd.name
  type                   = "Page"
  source_uri             = local.rhcos_image
  metadata               = tomap({ "source_uri" = local.rhcos_image })
}

resource "azurerm_image" "cluster" {
  name                = local.cluster_id
  resource_group_name = var.rg_uat_05
  location            = var.location
  os_disk {
    os_type      = "Linux"
    os_state     = "Generalized"
    storage_type = "Standard_LRS"
    blob_uri     = azurerm_storage_blob.rhcos_image.url
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "Cluster Image"
  }
}


## Update the storage account to use private endpoint and disable public access
resource "azurerm_private_endpoint" "storage_private_endpoint" {
  name                = "${module.storage_account.storage_account_name}-pe"
  location            = var.location
  resource_group_name = var.rg_uat_05
  subnet_id           = module.network_uat_application_01.storage_account_subnet_id

  private_service_connection {
    name                           = "${module.storage_account.storage_account_name}-psc"
    private_connection_resource_id = module.storage_account.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  depends_on = [module.master, azurerm_private_endpoint.storage_private_endpoint]
}

resource "azurerm_storage_account_network_rules" "storage_rules" {
  storage_account_id = module.storage_account.storage_account_id

  # Disable public access
  default_action = "Deny"

  # Allow access through private endpoint
  bypass = ["AzureServices"]

  depends_on = [module.master, azurerm_private_endpoint.storage_private_endpoint]
}