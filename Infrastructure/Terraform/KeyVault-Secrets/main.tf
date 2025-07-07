data "azurerm_resource_group" "shared" {
  name     = "${var.environment}-${var.region}-${var.resource_group_name}"
}

data "azurerm_key_vault" "shared" {
  name                = "${var.environment}-${var.region}-${var.key_vault_name}"
  resource_group_name = "${data.azurerm_resource_group.shared.name}"
}

resource "azurerm_key_vault_secret" "mas-oms-name" {
  name         = "${var.environment}-${var.region}-${var.logicapp_container_service_name}-basicname"
  value        = "${var.keyvault_secret_mas_oms_basicname}"
  content_type = "plain/text"
  key_vault_id = "${data.azurerm_key_vault.shared.id}"
}

resource "azurerm_key_vault_secret" "mas-oms-secret" {
  name         = "${var.environment}-${var.region}-${var.logicapp_container_service_name}-basicpassword"
  value        = "${var.keyvault_secret_mas_oms_basicsecret}"
  content_type = "plain/text"
  key_vault_id = "${data.azurerm_key_vault.shared.id}"
}

resource "azurerm_key_vault_secret" "mas-oms-apikey" {
  name         = "${var.environment}-${var.region}-${var.logicapp_container_service_name}-apikey"
  value        = "${var.keyvault_secret_mas_oms_apikey}"
  content_type = "plain/text"
  key_vault_id = "${data.azurerm_key_vault.shared.id}"
}