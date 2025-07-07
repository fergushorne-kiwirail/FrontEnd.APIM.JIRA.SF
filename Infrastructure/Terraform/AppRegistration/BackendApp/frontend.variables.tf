variable "environment" {
  type        = string
  description = "environment name which will be appended to the resource names i.e. dv,ts,ut,pd"
}

variable "keyvault_integration_services" {
  type        = list
  description = "Specify the key vault instances to store secrets"
}

variable "azuread_application_owners" {
  type        = list
  description = "Specify the AAD UPN of the users that will be owners of the app reigstrations"
}