terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.22.0"
    }
  }
}



provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
  default_tags {
    tags = var.default_tags
  }
}

provider "vault" {
  address          = var.vault_address
  skip_child_token = true
  auth_login_userpass {
    username = var.vault_username
    password = var.vault_password
  }
}


data "aws_eks_cluster" "thanos" {
  name = var.name
}

data "aws_eks_cluster_auth" "thanos" {
  name = var.name
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.thanos.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.thanos.certificate_authority[0].data)
  #token                  = module.cluster.kubernetes_token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.name]
    command     = "aws"
  }
}


provider "kubectl" {
  host                   = data.aws_eks_cluster.thanos.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.thanos.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.thanos.token
  load_config_file       = false
}


provider "helm" {
  debug = true
  kubernetes {
    host                   = data.aws_eks_cluster.thanos.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.thanos.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.name]
      command     = "aws"
    }
  }
}






