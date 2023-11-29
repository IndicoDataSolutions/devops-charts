resource "helm_release" "thanos-pre-reqs" {
  depends_on = [
    vault_kubernetes_auth_backend_config.vault-auth,
    vault_kubernetes_auth_backend_role.vault-auth-role,
    kubernetes_secret_v1.vault-auth-default,
    kubernetes_service_account_v1.vault-auth-default,
    kubernetes_cluster_role_binding.vault-auth
  ]
  name              = "tpr"
  chart             = "thanos-pre-reqs"
  repository        = "./helm-charts"
  dependency_update = true
}

resource "helm_release" "thanos" {
  depends_on        = [helm_release.thanos-pre-reqs]
  name              = "t"
  chart             = "thanos"
  repository        = "./helm-charts"
  force_update      = true
  dependency_update = true
}

