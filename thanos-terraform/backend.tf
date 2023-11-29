terraform {
  cloud {
    organization = "indico"
    workspaces {
      name = "thanos-setup"
    }
  }
}
