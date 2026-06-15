# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "location" {
  description = "Location of the resources."
}

variable "prefix" {
  description = "Prefix of the resources."
}

variable "tenantId" {
  description = "Tenant ID."
}

variable "subscriptionId" {
  description = "Subscription ID"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = null
}

variable "kubeconfig_location" {
  description = "Location where to store kubeconfig file for the AKS cluster created"
}

variable "max_worker_nodes" {
  description = "Maximum number of nodes for a worker"
}

variable "environment" {
  description = "Azure Cloud Environment to use"
}

variable "enable_telemetry" {
  description = "Use telemetry"
  type        = bool
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

variable "node_os_sku" {
  description = "AKS node OS SKU for Linux node pools. Ubuntu avoids the retired Mariner/Azure Linux 2 image while AzureRM 3.x remains pinned."
  default     = "Ubuntu"
}

variable "ingress_controller_type" {
  description = "Ingress controller mode. Use self_managed_nginx for the Helm ingress-nginx release or application_routing for AKS Application Routing managed NGINX."
  default     = "self_managed_nginx"
}

variable "application_routing_dns_zone_ids" {
  description = "Azure DNS zone IDs to integrate with AKS Application Routing. Leave empty when not using bring-your-own DNS zones."
  type        = list(string)
  default     = []
}
