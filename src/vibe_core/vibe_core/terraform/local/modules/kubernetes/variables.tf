# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "namespace" {
  description = "Namespace"
}

variable "kubernetes_config_path" {
}

variable "kubernetes_config_context" {
}

variable "host_storage_path" {
}

variable "redis_image_tag" {
}

variable "rabbitmq_chart_version" {
}

variable "rabbitmq_image_tag" {
}

variable "dapr_runtime_version" {
  description = "Dapr runtime and Helm chart version. Keep Python SDK pins separate until runtime compatibility is validated."
  default     = "1.15.10"
}

variable "enable_telemetry" {
  description = "Use telemetry"
  type        = bool
}