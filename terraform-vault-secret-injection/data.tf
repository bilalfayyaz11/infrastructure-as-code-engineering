data "vault_kv_secret_v2" "db" {
  mount = "secret"
  name  = "database/prod"
}

data "vault_kv_secret_v2" "api" {
  mount = "secret"
  name  = "api/external-service"
}
