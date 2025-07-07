# Get data from resource provider #
data "azurerm_client_config" "current" {}

## Retrieve User Objects to Add as Owners of applications ##
data "azuread_user" "user_collection" {
  for_each      = { for x in var.azuread_application_owners: x => x }
  user_principal_name = "${each.value}"
}

# Helper functions #
resource "random_uuid" "mas_sap_backend_read_role_scope_id" {}

# Create resources #
resource "azuread_application" "mas_sap_backend_app" {
  display_name               = "Integration-APIM-MAS-SAP-Backend-APP-${var.environment}"
  prevent_duplicate_names    = true
  owners                     = "${values(data.azuread_user.user_collection).*.object_id}"
  api {
    requested_access_token_version = 2
  }

  app_role {
    allowed_member_types = ["Application"]
    description          = "Allow the application to pull data from MAS"
    display_name         = "SAP.SendAssetInfo"
    enabled              = true
    id                   = random_uuid.mas_sap_backend_read_role_scope_id.result
    value                = "SAP.SendAssetInfo"
  }

  lifecycle {
  # Cannot set identity URL to the app registration appid which is default behaviour. https://github.com/hashicorp/terraform-provider-azuread/issues/428
  # Do this manually and ignore so terraform doesnt revert the change
    ignore_changes = [identifier_uris]
  }
}

# Store Mas-SAP Backend Application ID to Key Vault #
resource "azurerm_key_vault_secret" "mas_sap_backend_app_id" {
  for_each      = { for x in var.keyvault_integration_services: x.keyvault_name => x }
  
  name         = "aad-mas-sap-backend-app-id"
  value        = azuread_application.mas_sap_backend_app.application_id
  content_type = "plain/text"
  key_vault_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${each.value.keyvault_resource_group}/providers/Microsoft.KeyVault/vaults/${each.value.keyvault_name}"
}


# Create Backend Application Service Principal #

resource "azuread_service_principal" "mas_sap_backend_app" {
  application_id               = azuread_application.mas_sap_backend_app.application_id
  app_role_assignment_required = false
  tags = [ "operations", "backend-api", "apim", "mas-sap", "integration-services"]
}

resource "null_resource" "azure-cli-azuread-identifier-uris" {
  provisioner "local-exec" {
      command = <<-EOT
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
      az ad app update --display-name "Integration-APIM-MAS-SAP-Backend-APP-${var.environment}" --id ${azuread_application.mas_sap_backend_app.application_id} --identifier-uris "api://${azuread_application.mas_sap_backend_app.application_id}"
      
  EOT
  }

  depends_on = [azuread_service_principal.mas_sap_backend_app]
}