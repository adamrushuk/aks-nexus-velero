# https://www.terraform.io/docs/providers/helm/d/repository.html
data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}
