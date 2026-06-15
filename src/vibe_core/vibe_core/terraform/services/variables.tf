# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "prefix" {
  description = "Prefix for resources"
}

variable "namespace" {
  description = "Namespace"
}

variable "kubernetes_config_path" {
}

variable "kubernetes_config_context" {
}

variable "worker_node_pool_name" {
}

variable "default_node_pool_name" {
  default = "default"
}

variable "acr_registry" {
}

variable "public_ip_fqdn" {
}

variable "dapr_sidecars_deployed" {
}

variable "working_dir" {
  default = ""
}

variable "run_as_user_id" {
  default = ""
}

variable "run_as_group_id" {
  default = ""
}

variable "log_dir" {
  default = ""
}

variable "max_log_file_bytes" {
  default = ""
}

variable "log_backup_count" {
  default = ""
}

variable "host_assets_dir" {
  default = ""
}

variable "local_deployment" {
  default = false
}

variable "image_prefix" {
  default = "terravibes-"
}

variable "image_tag" {
  default = "latest"
}

variable "worker_memory_request" {
  default = "8Gi"
}

variable "startup_type" {
}

variable "shared_resource_pv_claim_name" {
}

variable "otel_service_name" {
}

variable "worker_replicas" {
  default = 1
}

variable "farmvibes_log_level" {
  default = "INFO"
}

variable "environment" {
  description = "Unused"
  default     = ""
}

variable "ingress_controller_type" {
  description = "Ingress controller mode. Use self_managed_nginx for the Helm ingress-nginx release or application_routing for AKS Application Routing managed NGINX."
  default     = "self_managed_nginx"
}

variable "ingress_class_name" {
  description = "Kubernetes IngressClass name for non-local deployments. The root module supplies the selected default unless explicitly overridden."
  default     = ""
}

variable "redis_host" {
  description = "Redis host used by the cache metadata store. Defaults to the in-cluster Redis service in the deployment namespace."
  default     = ""
}

variable "redis_port" {
  description = "Redis port used by the cache metadata store."
  default     = "6379"
}

variable "redis_db" {
  description = "Redis database index used by the cache metadata store."
  default     = "0"
}

variable "redis_username" {
  description = "Redis username used by the cache metadata store. Leave empty for the in-cluster Redis chart."
  default     = ""
}

variable "redis_ssl" {
  description = "Whether the cache metadata store should connect to Redis with TLS."
  default     = "false"
}

variable "redis_metadata_ttl_seconds" {
  description = "TTL for new Redis cache metadata keys. Set 0 to disable expiration."
  default     = "2592000"
}
