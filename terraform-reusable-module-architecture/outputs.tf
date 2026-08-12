output "readme_path" {
  description = "Path of the README file created by the module"
  value       = module.readme_file.file_path
}

output "config_path" {
  description = "Path of the configuration file created by the module"
  value       = module.config_file.file_path
}

output "config_content_md5" {
  description = "MD5 hash of the generated configuration file content"
  value       = module.config_file.content_md5
}
