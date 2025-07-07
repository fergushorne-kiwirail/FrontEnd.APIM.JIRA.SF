variable "environment" {
  type        = string
  description = "environment name which will be appended to the resource names i.e. dv,ts,ut,pd"
}

variable "environmentURL" {
  type        = string
  description = "environment name which will be appended to the resource names i.e. dv,ts,ut,pd"
}

variable "region" {
  type        = string
  description = "Region where we will be deploying our resources to to i.e. Australia East(aue),Australia SouthEast(aus)"
}

variable "frontend_resource_group_name" {
  type        = string
  default     = "integrationfrontend-rg"
  description = "Frontend Resource group name resources will be deployed to"
}

variable "shared_resource_group_name" {
  type        = string
  default     = "integrationshared-rg"
  description = "Shared Resource group name resources will be deployed to"
}

variable "application_insights_name" {
  type        = string
  default     = "integration-appinsight"
  description = "Specify the name for the app insights service which will be used by the API"
}

variable "api_management_name" {
  type        = string
  default     = "kiwirail-apimanager-apim"
  description = "Specify the name for the api management service"
}

variable "keyvault_name" {
  type        = string
  default     = "integration-kv"
  description = "Specify the name for the key vault"
}

variable "ws-mas-sap-workorder-wf-urlsignature" {
  type        = string
  description = "URL signature for the workflow"
}

variable "ws-mas-sap-purchaseorder-wf-urlsignature" {
  type        = string
  description = "URL signature for the workflow"
}

variable "ws-mas-sap-reservations-wf-urlsignature" {
  type        = string
  description = "URL signature for the workflow"
}

variable "frontdoor_id" {
  type        = string
  description = "Frontdoor ID"
}