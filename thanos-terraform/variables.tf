
variable "aws_access_key" {
  type        = string
  description = "The AWS access key to use for deployment"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key to use for deployment"
  sensitive   = true
}

variable "default_tags" {
  type        = map(string)
  default     = null
  description = "Default tags to add to each resource"
}


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
  default = "monitoring"
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
