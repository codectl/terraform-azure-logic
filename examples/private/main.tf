module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 3.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 10.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.20.0.0/16"]

    subnets = {
      sn1 = {
        network_security_group = {}
        address_prefixes       = ["10.20.1.0/24"]
        delegations = {
          web = {
            name = "Microsoft.Web/serverFarms"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/action",
            ]
          }
        }
      }
      sn2 = {
        network_security_group = {}
        address_prefixes       = ["10.20.2.0/24"]
      }
    }
  }
}

module "storage" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 5.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "appservice" {
  source  = "cloudnationhq/plan/azure"
  version = "~> 4.0"

  plans = {
    dev = {
      name                = module.naming.app_service_plan.name
      location            = module.rg.groups.demo.location
      resource_group_name = module.rg.groups.demo.name
      os_type             = "Windows"
      sku_name            = "WS1"
    }
  }
}

module "logic" {
  source  = "cloudnationhq/logic/azure"
  version = "~> 2.0"

  logic_app = {
    name                       = module.naming.logic_app_standard.name_unique
    location                   = module.rg.groups.demo.location
    resource_group_name        = module.rg.groups.demo.name
    app_service_plan_id        = module.appservice.plans.dev.id
    storage_account_name       = module.storage.account.name
    storage_account_access_key = module.storage.account.primary_access_key
    virtual_network_subnet_id  = module.network.subnets.sn1.id
    vnet_content_share_enabled = true
    public_network_access      = "Disabled"
    https_only                 = true

    site_config = {
      vnet_route_all_enabled            = true
      ip_restriction_default_action     = "Deny"
      scm_ip_restriction_default_action = "Deny"
      min_tls_version                   = "1.2"

      ip_restrictions = {
        integration = {
          name                      = "allow-integration-subnet"
          priority                  = 100
          action                    = "Allow"
          virtual_network_subnet_id = module.network.subnets.sn1.id
          description               = "inbound traffic from the integration subnet"
        }
        frontdoor = {
          name        = "allow-front-door"
          priority    = 200
          action      = "Allow"
          service_tag = "AzureFrontDoor.Backend"
          description = "inbound traffic from a specific front door instance only"

          headers = {
            x_azure_fdid      = ["11111111-2222-3333-4444-555555555555"]
            x_fd_health_probe = ["1"]
          }
        }
      }

      scm_ip_restrictions = {
        corporate = {
          name        = "allow-corporate-range"
          priority    = 100
          action      = "Allow"
          ip_address  = "198.51.100.0/24"
          description = "deployments are restricted to the corporate range"
        }
      }
    }
  }
}

module "private_dns" {
  source  = "cloudnationhq/pdns/azure"
  version = "~> 5.0"

  resource_group_name = module.rg.groups.demo.name

  zones = {
    private = {
      web = {
        name = "privatelink.azurewebsites.net"
        virtual_network_links = {
          link1 = {
            virtual_network_id   = module.network.vnet.id
            registration_enabled = true
          }
        }
      }
    }
  }
}

module "privatelink" {
  source  = "cloudnationhq/pe/azure"
  version = "~> 3.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  endpoints = {
    logic = {
      name      = module.naming.private_endpoint.name
      subnet_id = module.network.subnets.sn2.id

      private_dns_zone_group = {
        private_dns_zone_ids = [module.private_dns.private_zones.web.id]
      }

      private_service_connection = {
        private_connection_resource_id = module.logic.logic_app_standard.id
        subresource_names              = ["sites"]
      }
    }
  }
}
