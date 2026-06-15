# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "location" {
  description = "Azure Location of the resources."
}

variable "prefix" {
  description = "Prefix of the resources. (3-5 chars)"
}

variable "tenantId" {
  description = "Azure Tenant ID."
}

variable "subscriptionId" {
  description = "Subscription ID"
}

variable "namespace" {
  description = "Namespace"
}

variable "acr_registry" {
  description = "ACR Registry"
}

variable "acr_registry_username" {
  description = "ACR Registry Username"
  default     = ""
}

variable "acr_registry_password" {
  description = "ACR Registry Password"
  default     = ""
}

variable "resource_group_name" {
  description = "If you want use an existing RG, specify it here. Else leave empty. Should be in the same Location as requested"
  default     = null
}

variable "enable_telemetry" {
  description = "Use telemetry"
  type        = bool
}

variable "monitor_instrumentation_key" {
  description = "Instrumentation Key for Azure Monitor"
  default     = null
}

variable "monitor_ingestion_endpoint" {
  description = "Azure Monitor ingestion endpoint for the OpenTelemetry collector. Leave null to use the Application Insights resource connection string."
  default     = null
}

variable "aks_diagnostic_log_category_exclusions" {
  description = "AKS diagnostic log categories to exclude when telemetry is enabled. Audit categories are high-volume, so they are excluded by default."
  type        = list(string)
  default     = ["kube-audit", "kube-audit-admin"]
}

variable "enable_monitor_alerts" {
  description = "Create Azure Monitor scheduled-query alerts when telemetry is enabled and monitor_action_group_ids is not empty."
  type        = bool
  default     = true
}

variable "monitor_action_group_ids" {
  description = "Azure Monitor Action Group resource IDs notified by FarmVibes operational alerts. Leave empty to skip alert creation."
  type        = list(string)
  default     = []
}

variable "monitor_alert_evaluation_frequency" {
  description = "ISO 8601 frequency for evaluating FarmVibes scheduled-query alerts."
  default     = "PT5M"
}

variable "monitor_alert_window_duration" {
  description = "ISO 8601 lookback window for FarmVibes scheduled-query alerts."
  default     = "PT15M"
}

variable "image_prefix" {
  default = "terravibes-"
}

variable "image_tag" {
}

variable "worker_replicas" {
  default = 1
}

variable "size_of_shared_volume" {
  default = "10Gi"
}

variable "certificate_email" {
  description = "Email to send information about certificates being generated"
}

variable "farmvibes_log_level" {
  description = "Log level to use with FarmVibes.AI services"
}

variable "node_os_sku" {
  description = "AKS node OS SKU for Linux node pools. Ubuntu avoids the retired Mariner/Azure Linux 2 image while AzureRM 3.x remains pinned."
  default     = "Ubuntu"
}

variable "rabbitmq_chart_version" {
  description = "Bitnami RabbitMQ Helm chart version. Keep this paired with rabbitmq_image_tag."
  default     = "16.0.14"
}

variable "rabbitmq_image_tag" {
  description = "Bitnami RabbitMQ image tag used by the Helm chart. Keep this paired with rabbitmq_chart_version."
  default     = "4.1.3-debian-12-r1"
}

variable "dapr_runtime_version" {
  description = "Dapr runtime and Helm chart version. Keep Python SDK pins separate until runtime compatibility is validated."
  default     = "1.15.10"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version."
  default     = "v1.19.1"
}

variable "ingress_controller_type" {
  description = "Ingress controller mode. Use self_managed_nginx for the Helm ingress-nginx release or application_routing for AKS Application Routing managed NGINX."
  default     = "self_managed_nginx"
}

variable "ingress_class_name" {
  description = "Override the Kubernetes IngressClass name. Leave empty to use nginx for self-managed ingress or farmvibes-webapprouting for AKS Application Routing."
  default     = ""
}

variable "application_routing_dns_zone_ids" {
  description = "Azure DNS zone IDs to integrate with AKS Application Routing. Leave empty when not using bring-your-own DNS zones."
  type        = list(string)
  default     = []
}
