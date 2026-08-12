variable "filename" {
  description = "Path/name of the file to create"
  type        = string
}

variable "content" {
  description = "Content to write into the file"
  type        = string
  default     = "Managed by Terraform."
}

variable "file_permission" {
  description = "Permission bits for the file"
  type        = string
  default     = "0644"
}
