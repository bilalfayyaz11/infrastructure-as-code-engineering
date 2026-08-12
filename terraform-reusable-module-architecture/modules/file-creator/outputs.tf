output "file_path" {
  description = "Path of the created file"
  value       = local_file.this.filename
}

output "file_id" {
  description = "Terraform resource ID of the file"
  value       = local_file.this.id
}

output "content_md5" {
  description = "MD5 hash of the created file content"
  value       = local_file.this.content_md5
}
