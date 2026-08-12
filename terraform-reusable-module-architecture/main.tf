terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

module "readme_file" {
  source   = "./modules/file-creator"
  filename = "${path.module}/output/README.txt"
  content  = "This file was created by Terraform module 1."
}

module "config_file" {
  source          = "./modules/file-creator"
  filename        = "${path.module}/output/app.conf"
  content         = "env=production\nversion=2.0"
  file_permission = "0600"
}
