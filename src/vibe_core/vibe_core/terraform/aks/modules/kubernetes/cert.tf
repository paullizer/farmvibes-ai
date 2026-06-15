# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "helm_release" "letsencrypt" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "kube-system"
  version    = var.cert_manager_chart_version

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "crds.keep"
    value = "true"
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "startupapicheck.enabled"
    value = "false"
  }

}

locals {
  ingress_class_name = var.ingress_class_name != "" ? var.ingress_class_name : var.ingress_controller_type == "application_routing" ? "farmvibes-webapprouting" : "nginx"
}

resource "kubectl_manifest" "clusterissuer" {
  yaml_body = <<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt
      namespace: kube-system
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.certificate_email}
        privateKeySecretRef:
          name: letsencrypt
        solvers:
        - http01:
            ingress:
              ingressClassName: ${local.ingress_class_name}
              podTemplate:
                spec:
                  nodeSelector:
                    "kubernetes.io/os": linux
    EOF

  depends_on = [helm_release.letsencrypt]
}