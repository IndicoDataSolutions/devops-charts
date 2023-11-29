terraform {
  cloud {
    organization = "indico"
    workspaces {
      name = "thanos-monitoring-setup"
    }
  }
}
