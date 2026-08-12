terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "config_a" {
  filename = "${path.module}/files/config_a.txt"
  content  = "environment=dev\nversion=1.0\n"
}

resource "local_file" "config_b" {
  filename = "${path.module}/files/config_b.txt"
  content  = "environment=staging\nversion=1.0\n"
}

resource "local_file" "config_c" {
  filename = "${path.module}/files/config_c.txt"
  content  = "environment=prod\nversion=1.0\n"
}
