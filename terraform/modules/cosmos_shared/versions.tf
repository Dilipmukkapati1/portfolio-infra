terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.31"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
