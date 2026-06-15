# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "kubectl_manifest" "application_routing_nginx_controller" {
  count = var.ingress_controller_type == "application_routing" ? 1 : 0

  yaml_body = <<-EOF
    apiVersion: approuting.kubernetes.azure.com/v1alpha1
    kind: NginxIngressController
    metadata:
      name: farmvibes-nginx
    spec:
      ingressClassName: ${local.ingress_class_name}
      controllerNamePrefix: farmvibes-nginx
      loadBalancerAnnotations:
        service.beta.kubernetes.io/azure-pip-name: "${var.public_ip_name}"
        service.beta.kubernetes.io/azure-load-balancer-resource-group: "${var.public_ip_resource_group}"
    EOF

  depends_on = [data.kubernetes_namespace.kubernetesnamespace]
}