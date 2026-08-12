locals {
  app_config = {
    db_username  = data.vault_kv_secret_v2.db.data["db_username"]
    db_password  = data.vault_kv_secret_v2.db.data["db_password"]
    api_key      = data.vault_kv_secret_v2.api.data["api_key"]
    api_endpoint = data.vault_kv_secret_v2.api.data["api_endpoint"]
  }
}

resource "local_sensitive_file" "app_config" {
  filename        = "${path.module}/output/app_config.conf"
  file_permission = "0600"

  content = templatefile("${path.module}/templates/app_config.tftpl", {
    db_username  = local.app_config.db_username
    db_password  = local.app_config.db_password
    api_key      = local.app_config.api_key
    api_endpoint = local.app_config.api_endpoint
  })
}
