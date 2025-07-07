## Get data from resources ##
# Get curent client config #
data "azurerm_client_config" "current" {}


# Retrieve Data Sources #
data "azuread_application" "mas_sap_backend_app" {
  display_name = "Integration-APIM-MAS-SAP-Backend-APP-${var.environment}"
}

# Retrieve User Objects to Add as Owners of applications #
data "azuread_user" "user_collection" {
  for_each      = { for x in var.azuread_application_owners: x => x }

  user_principal_name = "${each.value}"
}

## Create resources in Azure ##
# Create Client Application for MAS-SAP API Consumer #
resource "azuread_application" "mas_sap_client_app" {
  display_name               = "Integration-APIM-MAS-SAP-Client-APP-${var.environment}"
  prevent_duplicate_names    = true
  owners                     = "${values(data.azuread_user.user_collection).*.object_id}"

  required_resource_access {
      resource_app_id = "${data.azuread_application.mas_sap_backend_app.application_id}"
      resource_access {
          id   = "${data.azuread_application.mas_sap_backend_app.app_role_ids["SAP.SendAssetInfo"]}"
          type = "Role"
      }
  }
}

# Create mas-sap Client Application Service Principal #
resource "azuread_service_principal" "mas_sap_client_app" {
  application_id               = azuread_application.mas_sap_client_app.application_id
  app_role_assignment_required = false
  tags                         = [ "operations", "backend-api", "apim", "mas", "integration-services"]
}

# Create mas-sap Client Application Secret and Store Client ID and Client Secret on Key Vault #
resource "azuread_application_password" "mas_sap_client_app" {
  application_object_id = azuread_application.mas_sap_client_app.id
  display_name          = "Client-Secret"
  end_date              = "2099-01-01T01:02:03Z"
}

resource "azurerm_key_vault_secret" "mas_sap_client_app_id" {
  for_each      = { for x in var.keyvault_integration_services: x.keyvault_name => x }

  name         = "aad-mas-sap-client-app-id"
  value        = azuread_application.mas_sap_client_app.application_id
  content_type = "plain/text"
  key_vault_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.keyvault_resource_group}/providers/Microsoft.KeyVault/vaults/${each.value.keyvault_name}"
}

resource "azurerm_key_vault_secret" "mas_sap_client_app_secret" {
  for_each      = { for x in var.keyvault_integration_services: x.keyvault_name => x }

  name         = "aad-mas-sap-client-app-secret"
  value        = azuread_application_password.mas_sap_client_app.value
  content_type = "plain/text"
  key_vault_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.keyvault_resource_group}/providers/Microsoft.KeyVault/vaults/${each.value.keyvault_name}"
}