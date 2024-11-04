provider "aws" {
  region = var.aws_region
}

provider "google" {
  project     = var.googleCloud.project
  region      = var.googleCloud.region
  credentials = file(var.googleCloud.credentials)
}

provider "azurerm" {
  features {}
}
