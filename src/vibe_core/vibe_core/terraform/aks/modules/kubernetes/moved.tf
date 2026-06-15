# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

moved {
  from = kubernetes_namespace.kubernetesnginxnamespace
  to   = kubernetes_namespace.kubernetesnginxnamespace[0]
}

moved {
  from = helm_release.nginx-ingress
  to   = helm_release.nginx-ingress[0]
}