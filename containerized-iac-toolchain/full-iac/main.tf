terraform {
  required_version = ">= 1.15.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

resource "local_file" "sample" {
  filename = "${path.module}/sample_output.txt"
  content  = "Hello from Terraform inside Docker\n"
}

output "generated_file" {
  value = local_file.sample.filename
}
