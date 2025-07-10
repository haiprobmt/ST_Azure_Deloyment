pull_secret = "<your_pull_secret_here>"

azure_private = true
airgapped     = {
  enabled     = true
  repository  = "ltabmms.azurecr.io/ocp4/openshift4"
}

## ST
subscription_id = ""
tenant_id = ""
azure_client_id = ""
azure_client_secret = ""
base_domain = ""


cluster_name = "ocp4"
location = "Southeast Asia"
environment = "uat"
project = "lta"
proxy_config =  {
    enabled    = false
    httpProxy  = "http://user:password@ip:port"
    httpsProxy = "http://user:password@ip:port"
    noProxy    = "ip1,ip2,ip3,.example.com,cidr/mask"
  }
