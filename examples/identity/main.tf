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

module "storage" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 5.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "uai" {
  source  = "cloudnationhq/uai/azure"
  version = "~> 3.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 6.0"

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
  source  = "cloudnationhq/rbac/azure"
  version = "~> 4.0"

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
