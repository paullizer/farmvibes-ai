# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "helm_release" "redis" {
  name = "redis"

  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  namespace  = var.namespace

  set {
    name  = "auth.enabled"
    value = "true"
  }

  set {
    name  = "master.containerPort"
    value = "6379"
  }

  set {
    name  = "replica.replicaCount"
    value = "0"
  }

  set {
    name  = "master.resources.requests.memory"
    value = var.redis_master_memory_request
  }

  set {
    name  = "master.resources.limits.memory"
    value = var.redis_master_memory_limit
  }

  set {
    name  = "master.resources.requests.cpu"
    value = var.redis_master_cpu_request
  }

  set {
    name  = "master.resources.limits.cpu"
    value = var.redis_master_cpu_limit
  }

  set {
    name  = "master.persistence.size"
    value = var.redis_master_persistence_size
  }

  depends_on = [data.kubernetes_namespace.kubernetesnamespace]
}

data "kubernetes_service" "redis" {
  metadata {
    name      = "redis-master"
    namespace = var.namespace
  }

  depends_on = [helm_release.redis]
}
