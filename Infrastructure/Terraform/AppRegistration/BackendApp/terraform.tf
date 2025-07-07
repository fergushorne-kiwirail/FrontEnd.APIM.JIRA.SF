terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = "~> 2.82.0"
    azuread = "~> 2.8.0"
  }
  backend "azurerm" {}
}