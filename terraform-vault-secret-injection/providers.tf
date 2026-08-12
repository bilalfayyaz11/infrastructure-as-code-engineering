terraform {
  required_version = ">= 1.15.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}
