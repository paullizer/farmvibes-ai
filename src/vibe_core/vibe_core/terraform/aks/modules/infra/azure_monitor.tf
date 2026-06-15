# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "azurerm_log_analytics_workspace" "analyticsworkspace" {
  name                = "${var.prefix}-analytics-workspace-${resource.random_string.name_suffix.result}"
  count               = var.enable_telemetry ? 1 : 0
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "appinsights" {
  name                = "${var.prefix}-app-insights-${resource.random_string.name_suffix.result}"
  count               = var.enable_telemetry ? 1 : 0
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.analyticsworkspace[0].id
}

data "azurerm_monitor_diagnostic_categories" "aks" {
  count       = var.enable_telemetry ? 1 : 0
  resource_id = azurerm_kubernetes_cluster.kubernetes.id
}

locals {
  aks_diagnostic_log_categories = var.enable_telemetry ? [
    for category in data.azurerm_monitor_diagnostic_categories.aks[0].log_category_types : category
    if !contains(var.aks_diagnostic_log_category_exclusions, category)
  ] : []
}


resource "azurerm_monitor_diagnostic_setting" "diagsetting" {
  name                       = "${var.prefix}-diagsetting-${resource.random_string.name_suffix.result}"
  count                      = var.enable_telemetry ? 1 : 0
  target_resource_id         = azurerm_application_insights.appinsights[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analyticsworkspace[0].id

  enabled_log {
    category = "AppTraces"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aksdiagsetting" {
  name                       = "${var.prefix}-aks-diagsetting-${resource.random_string.name_suffix.result}"
  count                      = var.enable_telemetry ? 1 : 0
  target_resource_id         = azurerm_kubernetes_cluster.kubernetes.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.analyticsworkspace[0].id

  dynamic "enabled_log" {
    for_each = toset(local.aks_diagnostic_log_categories)

    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
  }
}
