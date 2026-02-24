variable "vault_token" {
  description = "The Vault Token used to authenticate (Root token or Admin token)"
  type        = string
  sensitive   = true # Terraform will hide this from logs
}

variable "vault_address" {
  description = "Public URL of the Vault server"
  type        = string
  default     = "https://vault.sikiru.co.uk"
}