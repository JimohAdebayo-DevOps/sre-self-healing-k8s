resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv"
  description = "Main storage for GridOps Application Secrets"

  # CHANGED: Specify the version explicitly here instead
  options = {
    version = "2"
  }
}