resource "helm_release" "thanos-pre-reqs" {
  name              = "tpr"
  chart             = "thanos-pre-reqs"
  repository        = "./helm-charts"
  dependency_update = true
}

resource "helm_release" "thanos" {
  depends_on        = [helm_release.thanos-pre-reqs]
  name              = "thanos"
  chart             = "thanos"
  repository        = "./helm-charts"
  dependency_update = true
}

