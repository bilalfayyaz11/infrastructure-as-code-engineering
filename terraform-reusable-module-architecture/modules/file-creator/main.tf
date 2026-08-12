terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

resource "local_file" "this" {
  filename        = var.filename
  content         = var.content
  file_permission = var.file_permission
}
