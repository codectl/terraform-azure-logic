module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "storage" {
  source  = "codectl/sa/azure"
  version = "~> 1.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "appservice" {
  source  = "codectl/plan/azure"
  version = "~> 1.0"

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
  source  = "codectl/logic/azure"
  version = "~> 1.0"

  logic_app = {
    name                       = module.naming.logic_app_standard.name_unique
    location                   = module.rg.groups.demo.location
    resource_group_name        = module.rg.groups.demo.name
    app_service_plan_id        = module.appservice.plans.dev.id
    storage_account_name       = module.storage.account.name
    storage_account_access_key = module.storage.account.primary_access_key

    app_settings = {
      "FUNCTIONS_WORKER_RUNTIME"     = "node"
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    }

    identity = {
      type = "SystemAssigned"
    }

    site_config = {
      always_on       = true
      http2_enabled   = true
      min_tls_version = "1.2"

      cors = {
        allowed_origins = ["https://portal.azure.com"]
      }
    }
  }
}
