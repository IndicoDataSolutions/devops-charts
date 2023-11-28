
variable "vault_address" {
  type    = string
  default = "https://vault.devops.indico.io"
}

variable "vault_username" {}
variable "vault_password" {
  sensitive = true
}

variable "account" {
  default = "Indico-Devops"
}
variable "region" {
  default = "us-east-2"
}
variable "name" {
  default = "thanos"
}

variable "kubernetes_host" {
  default = "https://B3FB481FCAF2EE9FEAC306857E171E19.yl4.us-east-2.eks.amazonaws.com"
}

variable "audience" {
  default = "vault"
}

locals {
  account_region_name = lower("${var.account}-${var.region}-${var.name}")
}
