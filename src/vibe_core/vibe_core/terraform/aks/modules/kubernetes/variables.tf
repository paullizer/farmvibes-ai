# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "tenantId" {
  description = "Tenant ID"
}

variable "namespace" {
  description = "Namespace"
}

variable "acr_registry" {
  description = "ACR Registry"
}

variable "acr_registry_username" {
  description = "ACR Registry Username"
}

variable "acr_registry_password" {
  description = "ACR Registry Password"
}

variable "kubernetes_config_path" {
  description = "Path where kubeconfig is located"
}

variable "kubernetes_config_context" {
}

variable "public_ip_address" {
}

variable "public_ip_fqdn" {
}

variable "public_ip_dns" {
}

variable "public_ip_name" {
}

variable "public_ip_resource_group" {
}

variable "keyvault_name" {
}

variable "application_id" {
}

variable "storage_connection_key" {
}

variable "storage_account_name" {
}

variable "userfile_container_name" {
}

variable "resource_group_name" {
}

variable "size_of_shared_volume" {
  default = "10Gi"
}

variable "monitor_instrumentation_key" {
}

variable "monitor_ingestion_endpoint" {
}

variable "certificate_email" {
  description = "Email to send information about certificates being generated"
}

variable "current_user_name" {
  description = "Current user name, used to add to the cluster-admin role"
}

variable "environment" {
  description = "Azure Cloud Environment to use"
}


variable "enable_telemetry" {
  description = "Use telemetry"
  type        = bool
}

variable "redis_master_memory_request" {
  description = "Memory request for the in-cluster Redis master."
  default     = "512Mi"
}

variable "redis_master_memory_limit" {
  description = "Memory limit for the in-cluster Redis master."
  default     = "2Gi"
}

variable "redis_master_cpu_request" {
  description = "CPU request for the in-cluster Redis master."
  default     = "250m"
}

variable "redis_master_cpu_limit" {
  description = "CPU limit for the in-cluster Redis master."
  default     = "1000m"
}

variable "redis_master_persistence_size" {
  description = "Persistent volume size for the in-cluster Redis master."
  default     = "8Gi"
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
  description = "Kubernetes IngressClass name for non-local deployments. The root module supplies the selected default unless explicitly overridden."
  default     = ""
}
