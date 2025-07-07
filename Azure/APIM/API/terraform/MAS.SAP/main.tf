data "azurerm_resource_group" "shared" {
  name = "${var.environment}-${var.region}-${var.shared_resource_group_name}"
}

data "azurerm_application_insights" "shared" {
  name                = "${var.environment}-${var.region}-${var.application_insights_name}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_resource_group" "frontend" {
  name = "${var.environment}-${var.region}-${var.frontend_resource_group_name}"
}

data "azurerm_api_management" "frontend" {
  name                = "${var.environment}-${var.region}-${var.api_management_name}"
  resource_group_name = data.azurerm_resource_group.frontend.name
}

data "azurerm_key_vault" "keyvault" {
  name                = "${var.environment}-${var.region}-${var.keyvault_name}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

resource "azurerm_api_management_api_version_set" "MASSAPAPIVersionSet" {
  name                = "mas-sap"
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  api_management_name = data.azurerm_api_management.frontend.name
  display_name        = "MAS SAP API"
  versioning_scheme   = "Segment"
}

# create API
resource "azurerm_api_management_api" "MASSAPV1API" {
  name                = "mas-sap-v1"
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  api_management_name = data.azurerm_api_management.frontend.name
  revision            = "1"
  version             = "v1"
  version_set_id      = azurerm_api_management_api_version_set.MASSAPAPIVersionSet.id
  path                = "sap"
  display_name        = "MAS SAP API V1"
  protocols           = ["https"]
  subscription_required = false

  depends_on = [azurerm_api_management_api_version_set.MASSAPAPIVersionSet]
}

# set api level policy
resource "azurerm_api_management_api_policy" "MASSAPV1APIPolicy" {
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name

  xml_content = <<XML
    <policies>
    <inbound>
        <base />
        <rate-limit calls="1000" renewal-period="60" />
        <!-- Validate and check if request is coming from Frontdoor and Maximo IP. If not return 403 -->
        <choose>
            <when condition="@(!(context.Request.Headers.GetValueOrDefault("X-Azure-FDID","").Contains("${var.frontdoor_id}")))">
                <return-response>
                    <set-status code="403" reason="Forbidden" />
                </return-response>
            </when>
        </choose>
        <set-header id="Auth" name="Auth" exists-action="override">
            <value>@(context.Request.Headers.GetValueOrDefault("Authorization", "").Split(' ').Last())</value>
        </set-header>
        <set-header name="Authorization" exists-action="delete" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
  XML

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

# create an operation for KRSAPReservationInterface
resource "azurerm_api_management_api_operation" "KRSAPReservationInterface" {
  operation_id        = "KRSAPReservationInterface"
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  display_name        = "KRSAPReservationInterface"
  method              = "POST"
  url_template        = "/KRSAPReservationInterface"
  description         = "Request SAP Reservation Interface."

  response {
    status_code = 202
    description = "Request has been accepted."
  }
  response {
    status_code = 401
    description = "Unauthorized"
  }

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

resource "azurerm_api_management_api_operation_policy" "KRSAPReservationInterface" {
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  operation_id        = azurerm_api_management_api_operation.KRSAPReservationInterface.operation_id

  xml_content = <<XML
    <policies>
        <inbound>
            <base />
            <set-backend-service base-url="https://${var.environmentURL}-${var.region}-integration-mas-sap-logic.azurewebsites.net:443/api/ws-mas-sap-reservations-wf/triggers" />
            <rewrite-uri template="/manual/invoke?api-version=2022-05-01&amp;sp=/triggers/manual/run&amp;sv=1.0&amp;sig={{apim-api-mas-sap_ws-mas-sap-reservations-wf-urlsignature}}" />
            <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />
        </inbound>
        <backend>
            <base />
        </backend>
        <outbound>
            <base />
        </outbound>
        <on-error>
            <base />
        </on-error>
    </policies>
XML

  depends_on = [
    azurerm_api_management_api.MASSAPV1API,
    azurerm_api_management_api_operation.KRSAPReservationInterface
  ]
}

# create an operation for KRSAPPOInterface
resource "azurerm_api_management_api_operation" "KRSAPPOInterface" {
  operation_id        = "KRSAPPOInterface"
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  display_name        = "KRSAPPOInterface"
  method              = "POST"
  url_template        = "/KRSAPPOInterface"
  description         = "Request SAP PO Interface."

  response {
    status_code = 202
    description = "Request has been accepted."
  }
  response {
    status_code = 401
    description = "Unauthorized"
  }

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

resource "azurerm_api_management_api_operation_policy" "KRSAPPOInterface" {
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  operation_id        = azurerm_api_management_api_operation.KRSAPPOInterface.operation_id

  xml_content = <<XML
    <policies>
        <inbound>
            <base />
            <set-backend-service base-url="https://${var.environmentURL}-${var.region}-integration-mas-sap-logic.azurewebsites.net:443/api/ws-mas-sap-purchaseorder-wf/triggers" />
            <rewrite-uri template="/manual/invoke?api-version=2022-05-01&amp;sp=/triggers/manual/run&amp;sv=1.0&amp;sig={{apim-api-mas-sap_ws-mas-sap-purchaseorder-wf-urlsignature}}" />
            <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />
            <set-header name="SOAPAction" exists-action="override">
                <value>http://sap.com/xi/WebService/soap1.1</value>
            </set-header>
        </inbound>
        <backend>
            <base />
        </backend>
        <outbound>
            <base />
        </outbound>
        <on-error>
            <base />
        </on-error>
    </policies>
XML

  depends_on = [
    azurerm_api_management_api.MASSAPV1API,
    azurerm_api_management_api_operation.KRSAPPOInterface
  ]
}

# create an operation for KRSAPWOInterface
resource "azurerm_api_management_api_operation" "KRSAPWOInterface" {
  operation_id        = "KRSAPWOInterface"
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  display_name        = "KRSAPWOInterface"
  method              = "POST"
  url_template        = "/KRSAPWOInterface"
  description         = "Request SAP Workorder Interface."

  response {
    status_code = 202
    description = "Request has been accepted."
  }
  response {
    status_code = 401
    description = "Unauthorized"
  }

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

resource "azurerm_api_management_api_operation_policy" "KRSAPWOInterface" {
  api_name            = azurerm_api_management_api.MASSAPV1API.name
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  operation_id        = azurerm_api_management_api_operation.KRSAPWOInterface.operation_id

  xml_content = <<XML
    <policies>
        <inbound>
            <base />
            <set-backend-service base-url="https://${var.environmentURL}-${var.region}-integration-mas-sap-logic.azurewebsites.net:443/api/ws-mas-sap-workorder-wf/triggers" />
            <rewrite-uri template="/manual/invoke?api-version=2022-05-01&amp;sp=/triggers/manual/run&amp;sv=1.0&amp;sig={{apim-api-mas-sap_ws-mas-sap-workorder-wf-urlsignature}}" />
            <set-header id="apim-generated-policy" name="Ocp-Apim-Subscription-Key" exists-action="delete" />
        </inbound>
        <backend>
            <base />
        </backend>
        <outbound>
            <base />
        </outbound>
        <on-error>
            <base />
        </on-error>
    </policies>
XML

  depends_on = [
    azurerm_api_management_api.MASSAPV1API,
    azurerm_api_management_api_operation.KRSAPWOInterface,
    azurerm_api_management_named_value.apim-api-mas-sap_ws-mas-sap-workorder-wf-urlsignature
  ]
}

resource "azurerm_api_management_named_value" "apim-api-mas-sap_ws-mas-sap-workorder-wf-urlsignature" {
  name                = "apim-api-mas-sap_ws-mas-sap-workorder-wf-urlsignature"
  display_name        = "apim-api-mas-sap_ws-mas-sap-workorder-wf-urlsignature"
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  value               = var.ws-mas-sap-workorder-wf-urlsignature
  secret              = true

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

resource "azurerm_api_management_named_value" "apim-api-mas-sap_ws-mas-sap-purchaseorder-wf-urlsignature" {
  name                = "apim-api-mas-sap_ws-mas-sap-purchaseorder-wf-urlsignature"
  display_name        = "apim-api-mas-sap_ws-mas-sap-purchaseorder-wf-urlsignature"
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  value               = var.ws-mas-sap-purchaseorder-wf-urlsignature
  secret              = true

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}

resource "azurerm_api_management_named_value" "apim-api-mas-sap_ws-mas-sap-reservations-wf-urlsignature" {
  name                = "apim-api-mas-sap_ws-mas-sap-reservations-wf-urlsignature"
  display_name        = "apim-api-mas-sap_ws-mas-sap-reservations-wf-urlsignature"
  api_management_name = data.azurerm_api_management.frontend.name
  resource_group_name = data.azurerm_api_management.frontend.resource_group_name
  value               = var.ws-mas-sap-reservations-wf-urlsignature
  secret              = true

  depends_on = [
    azurerm_api_management_api.MASSAPV1API
  ]
}