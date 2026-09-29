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

module "uai" {
  source  = "codectl/uai/azure"
  version = "~> 1.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      predefined_string = {
        storage = {
          name  = "storage-connection-string"
          value = module.storage.account.primary_connection_string
        }
      }
    }
  }
}

module "rbac" {
  source  = "codectl/rbac/azure"
  version = "~> 1.0"

  role_assignments = {
    logic = {
      object_id = module.uai.identity.principal_id
      type      = "ServicePrincipal"
      roles = {
        "Key Vault Secrets User" = {
          scopes = {
            kv = { id = module.kv.vault.id }
          }
        }
      }
    }
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

  depends_on = [module.rbac]

  logic_app = {
    name                            = module.naming.logic_app_standard.name_unique
    location                        = module.rg.groups.demo.location
    resource_group_name             = module.rg.groups.demo.name
    app_service_plan_id             = module.appservice.plans.dev.id
    storage_key_vault_secret_id     = module.kv.secrets.storage.versionless_id
    key_vault_reference_identity_id = module.uai.identity.id

    identity = {
      type         = "UserAssigned"
      identity_ids = [module.uai.identity.id]
    }

    app_settings = {
      "FUNCTIONS_WORKER_RUNTIME" = "node"
      "STORAGE_CONNECTION"       = "@Microsoft.KeyVault(SecretUri=${module.kv.secrets.storage.versionless_id})"
    }

    site_config = {
      always_on       = true
      min_tls_version = "1.2"
    }
  }
}
