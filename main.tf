resource "azurerm_logic_app_standard" "this" {
  resource_group_name = coalesce(
    var.logic_app.resource_group_name, var.resource_group_name
  )

  location = coalesce(
    var.logic_app.location, var.location
  )

  name                                     = var.logic_app.name
  app_service_plan_id                      = var.logic_app.app_service_plan_id
  storage_account_name                     = var.logic_app.storage_account_name
  storage_account_access_key               = var.logic_app.storage_account_access_key
  storage_key_vault_secret_id              = var.logic_app.storage_key_vault_secret_id
  app_settings                             = var.logic_app.app_settings
  use_extension_bundle                     = var.logic_app.use_extension_bundle
  bundle_version                           = var.logic_app.bundle_version
  client_affinity_enabled                  = var.logic_app.client_affinity_enabled
  client_certificate_mode                  = var.logic_app.client_certificate_mode
  enabled                                  = var.logic_app.enabled
  ftp_publish_basic_authentication_enabled = var.logic_app.ftp_publish_basic_authentication_enabled
  https_only                               = var.logic_app.https_only
  key_vault_reference_identity_id          = var.logic_app.key_vault_reference_identity_id
  public_network_access                    = var.logic_app.public_network_access
  scm_publish_basic_authentication_enabled = var.logic_app.scm_publish_basic_authentication_enabled
  storage_account_share_name               = var.logic_app.storage_account_share_name
  version                                  = var.logic_app.version
  virtual_network_subnet_id                = var.logic_app.virtual_network_subnet_id
  vnet_content_share_enabled               = var.logic_app.vnet_content_share_enabled

  tags = coalesce(
    var.logic_app.tags, var.tags
  )

  dynamic "connection_string" {
    for_each = var.logic_app.connection_strings

    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  dynamic "identity" {
    for_each = var.logic_app.identity != null ? { "this" = var.logic_app.identity } : {}

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "site_config" {
    for_each = var.logic_app.site_config != null ? { "this" = var.logic_app.site_config } : {}

    content {
      always_on                         = site_config.value.always_on
      app_scale_limit                   = site_config.value.app_scale_limit
      auto_swap_slot_name               = site_config.value.auto_swap_slot_name
      dotnet_framework_version          = site_config.value.dotnet_framework_version
      elastic_instance_minimum          = site_config.value.elastic_instance_minimum
      ftps_state                        = site_config.value.ftps_state
      health_check_path                 = site_config.value.health_check_path
      http2_enabled                     = site_config.value.http2_enabled
      ip_restriction_default_action     = site_config.value.ip_restriction_default_action
      linux_fx_version                  = site_config.value.linux_fx_version
      min_tls_version                   = site_config.value.min_tls_version
      pre_warmed_instance_count         = site_config.value.pre_warmed_instance_count
      runtime_scale_monitoring_enabled  = site_config.value.runtime_scale_monitoring_enabled
      scm_ip_restriction_default_action = site_config.value.scm_ip_restriction_default_action
      scm_min_tls_version               = site_config.value.scm_min_tls_version
      scm_type                          = site_config.value.scm_type
      scm_use_main_ip_restriction       = site_config.value.scm_use_main_ip_restriction
      use_32_bit_worker_process         = site_config.value.use_32_bit_worker_process
      vnet_route_all_enabled            = site_config.value.vnet_route_all_enabled
      websockets_enabled                = site_config.value.websockets_enabled

      dynamic "cors" {
        for_each = site_config.value.cors != null ? { "this" = site_config.value.cors } : {}

        content {
          allowed_origins     = cors.value.allowed_origins
          support_credentials = cors.value.support_credentials
        }
      }

      dynamic "ip_restriction" {
        for_each = site_config.value.ip_restrictions

        content {
          ip_address                = ip_restriction.value.ip_address
          service_tag               = ip_restriction.value.service_tag
          virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
          name                      = ip_restriction.value.name
          priority                  = ip_restriction.value.priority
          action                    = ip_restriction.value.action
          description               = ip_restriction.value.description

          dynamic "headers" {
            for_each = ip_restriction.value.headers != null ? { "this" = ip_restriction.value.headers } : {}

            content {
              x_azure_fdid      = headers.value.x_azure_fdid
              x_fd_health_probe = headers.value.x_fd_health_probe
              x_forwarded_for   = headers.value.x_forwarded_for
              x_forwarded_host  = headers.value.x_forwarded_host
            }
          }
        }
      }

      dynamic "scm_ip_restriction" {
        for_each = site_config.value.scm_ip_restrictions

        content {
          ip_address                = scm_ip_restriction.value.ip_address
          service_tag               = scm_ip_restriction.value.service_tag
          virtual_network_subnet_id = scm_ip_restriction.value.virtual_network_subnet_id
          name                      = scm_ip_restriction.value.name
          priority                  = scm_ip_restriction.value.priority
          action                    = scm_ip_restriction.value.action
          description               = scm_ip_restriction.value.description

          dynamic "headers" {
            for_each = scm_ip_restriction.value.headers != null ? { "this" = scm_ip_restriction.value.headers } : {}

            content {
              x_azure_fdid      = headers.value.x_azure_fdid
              x_fd_health_probe = headers.value.x_fd_health_probe
              x_forwarded_for   = headers.value.x_forwarded_for
              x_forwarded_host  = headers.value.x_forwarded_host
            }
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_CONTENTSHARE"],
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"]
    ]
  }
}
