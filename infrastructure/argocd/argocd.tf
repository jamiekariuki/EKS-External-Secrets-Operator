 #app of apps
resource "helm_release" "app_of_apps" {

  name       = "root-app"
  chart      = "${path.module}/app"
  namespace  = "argocd"

  values = [
    file("${path.module}/app/values.yaml")
  ]
}





