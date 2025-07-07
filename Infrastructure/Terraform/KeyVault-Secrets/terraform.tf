terraform {
  required_version = ">= 1.7.5"
  required_providers {
    azurerm = "~> 3.97.1"
  }
  backend "azurerm" {}
}