resource "helm_release" "thanos-pre-reqs" {
  name              = "tpr"
  chart             = "thanos-pre-reqs"
  repository        = "./helm-charts"
  dependency_update = true
}
