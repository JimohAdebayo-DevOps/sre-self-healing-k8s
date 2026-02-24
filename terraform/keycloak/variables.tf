variable "keycloak_url" {
  default = "https://sso.sikiru.co.uk"
}

variable "keycloak_user" {
  description = "The Admin Username (usually 'user' or 'admin')"
  type        = string
}

variable "keycloak_password" {
  description = "The Admin Password"
  type        = string
  sensitive   = true
}

variable "junior_initial_password" {
  description = "Temporary password for the junior-dev user"
  type        = string
  sensitive   = true
}