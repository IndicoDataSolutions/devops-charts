resource "helm_release" "thanos-pre-reqs" {
  name       = "tpr"
  chart      = "thanos-pre-reqs"
  repository = "./thanos-pre-reqs"
}
