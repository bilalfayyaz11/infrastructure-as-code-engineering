output "config_file_path" {
  description = "Path to the generated application configuration"
  value       = local_sensitive_file.app_config.filename
}

output "database_username" {
  description = "Database username retrieved from Vault"
  value       = data.vault_kv_secret_v2.db.data["db_username"]
  sensitive   = true
}
