# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  monitor_alerts_enabled = var.enable_telemetry && var.enable_monitor_alerts && length(var.monitor_action_group_ids) > 0
  container_insights_alerts = {
    "aks-node-not-ready" = {
      display_name = "AKS node not ready"
      description  = "One or more AKS nodes reported a non-Ready status in Container Insights."
      severity     = 1
      threshold    = 0
      query        = <<-QUERY
        KubeNodeInventory
        | where TimeGenerated > ago(15m)
        | where ClusterName == "${var.prefix}"
        | summarize AggregatedValue = countif(Status != "Ready")
      QUERY
    }

    "aks-pod-restarts" = {
      display_name = "AKS pod restarts"
      description  = "Multiple containers have restarted recently, which can indicate crash loops or node pressure."
      severity     = 2
      threshold    = 5
      query        = <<-QUERY
        KubePodInventory
        | where TimeGenerated > ago(15m)
        | where ClusterName == "${var.prefix}"
        | summarize Restarts = max(ContainerRestartCount) by ContainerID
        | summarize AggregatedValue = countif(Restarts > 0)
      QUERY
    }

    "farmvibes-pods-unhealthy" = {
      display_name = "FarmVibes pods unhealthy"
      description  = "FarmVibes service pods are not running successfully."
      severity     = 1
      threshold    = 0
      query        = <<-QUERY
        KubePodInventory
        | where TimeGenerated > ago(15m)
        | where ClusterName == "${var.prefix}"
        | where Namespace == "default"
        | where Name has_any ("terravibes-rest-api", "terravibes-worker", "terravibes-cache", "terravibes-data-ops", "terravibes-orchestrator")
        | summarize AggregatedValue = countif(PodStatus !in ("Running", "Succeeded"))
      QUERY
    }

    "platform-pods-unhealthy" = {
      display_name = "Platform pods unhealthy"
      description  = "Redis, RabbitMQ, Dapr, cert-manager, or ingress pods are not running successfully."
      severity     = 1
      threshold    = 0
      query        = <<-QUERY
        KubePodInventory
        | where TimeGenerated > ago(15m)
        | where ClusterName == "${var.prefix}"
        | where Namespace in ("dapr-system", "cert-manager", "app-routing-system", "ingress-nginx", "default")
        | where Namespace != "default" or Name has_any ("redis", "rabbitmq", "nginx")
        | summarize AggregatedValue = countif(PodStatus !in ("Running", "Succeeded"))
      QUERY
    }

    "image-pull-or-crash-loop" = {
      display_name = "Image pull or crash loop"
      description  = "A container is stuck in ImagePullBackOff, ErrImagePull, or CrashLoopBackOff."
      severity     = 1
      threshold    = 0
      query        = <<-QUERY
        KubePodInventory
        | where TimeGenerated > ago(15m)
        | where ClusterName == "${var.prefix}"
        | where ContainerStatusReason in ("ImagePullBackOff", "ErrImagePull", "CrashLoopBackOff")
        | summarize AggregatedValue = count()
      QUERY
    }

    "cert-manager-errors" = {
      display_name = "cert-manager errors"
      description  = "cert-manager logged renewal, order, or challenge errors."
      severity     = 2
      threshold    = 0
      query        = <<-QUERY
        union isfuzzy=true ContainerLogV2, ContainerLog
        | where TimeGenerated > ago(30m)
        | extend Namespace = tostring(iff(isnotempty(column_ifexists("PodNamespace", "")), column_ifexists("PodNamespace", ""), iff(isnotempty(column_ifexists("KubernetesNamespace", "")), column_ifexists("KubernetesNamespace", ""), column_ifexists("Namespace", ""))))
        | extend Message = tostring(iff(isnotempty(column_ifexists("LogMessage", "")), column_ifexists("LogMessage", ""), column_ifexists("LogEntry", "")))
        | where Namespace == "cert-manager"
        | where Message has_any ("failed", "error", "challenge", "order", "renew")
        | summarize AggregatedValue = count()
      QUERY
    }

    "otel-export-errors" = {
      display_name = "OpenTelemetry export errors"
      description  = "The in-cluster OpenTelemetry collector logged export or Azure Monitor errors."
      severity     = 2
      threshold    = 0
      query        = <<-QUERY
        union isfuzzy=true ContainerLogV2, ContainerLog
        | where TimeGenerated > ago(30m)
        | extend PodName = tostring(iff(isnotempty(column_ifexists("PodName", "")), column_ifexists("PodName", ""), column_ifexists("Name", "")))
        | extend Message = tostring(iff(isnotempty(column_ifexists("LogMessage", "")), column_ifexists("LogMessage", ""), column_ifexists("LogEntry", "")))
        | where PodName has "otel-collector"
        | where Message has_any ("export", "azuremonitor", "Application Insights", "error", "failed")
        | summarize AggregatedValue = count()
      QUERY
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "container_insights" {
  for_each = local.monitor_alerts_enabled ? local.container_insights_alerts : {}

  name                  = "${var.prefix}-${each.key}-${resource.random_string.name_suffix.result}"
  display_name          = each.value.display_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  evaluation_frequency  = var.monitor_alert_evaluation_frequency
  window_duration       = var.monitor_alert_window_duration
  scopes                = [azurerm_log_analytics_workspace.analyticsworkspace[0].id]
  severity              = each.value.severity
  description           = each.value.description
  enabled               = true
  skip_query_validation = true

  criteria {
    query                   = each.value.query
    time_aggregation_method = "Maximum"
    metric_measure_column   = "AggregatedValue"
    operator                = "GreaterThan"
    threshold               = each.value.threshold

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = var.monitor_action_group_ids
    custom_properties = {
      source = "farmvibes-ai"
    }
  }

  depends_on = [
    azurerm_kubernetes_cluster.kubernetes,
    azurerm_log_analytics_workspace.analyticsworkspace,
  ]
}