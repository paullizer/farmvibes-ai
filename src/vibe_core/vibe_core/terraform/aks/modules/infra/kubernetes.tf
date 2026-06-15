# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {
  default_node_pool_max_count = 3
}

resource "azurerm_kubernetes_cluster" "kubernetes" {
  name                      = var.prefix
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.prefix}kbsdns"
  automatic_channel_upgrade = "patch"
  node_os_channel_upgrade   = "NodeImage"
  oidc_issuer_enabled       = true

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  default_node_pool {
    name                        = "default"
    enable_auto_scaling         = true
    min_count                   = 2
    max_count                   = local.default_node_pool_max_count
    vm_size                     = "Standard_D4as_v6"
    os_sku                      = var.node_os_sku
    temporary_name_for_rotation = "defaulttmp"
    vnet_subnet_id              = azurerm_subnet.aks-subnet.id
  }

  storage_profile {
    blob_driver_enabled = true
  }

  dynamic "oms_agent" {
    for_each = var.enable_telemetry ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.analyticsworkspace[0].id
    }
  }

  dynamic "web_app_routing" {
    for_each = var.ingress_controller_type == "application_routing" ? [1] : []
    content {
      dns_zone_ids = var.application_routing_dns_zone_ids
    }
  }

  network_profile {
    network_plugin = "azure"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings,
    ]
  }

  depends_on = [azurerm_subnet.aks-subnet, data.azurerm_resource_group.resourcegroup]
}

data "azurerm_user_assigned_identity" "kubernetesidentity" {
  name                = "${azurerm_kubernetes_cluster.kubernetes.name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.kubernetes.node_resource_group

  depends_on = [azurerm_kubernetes_cluster.kubernetes]
}


resource "azurerm_kubernetes_cluster_node_pool" "kubernetes-worker" {
  name                  = "worker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes.id
  vm_size               = "Standard_D8as_v6"
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = var.max_worker_nodes
  os_sku                = var.node_os_sku
  depends_on            = [azurerm_kubernetes_cluster.kubernetes]

  lifecycle {
    ignore_changes = [
      upgrade_settings,
      vnet_subnet_id,
    ]
  }
}

resource "local_file" "kubeconfig" {
  filename   = "${var.kubeconfig_location}/kubeconfig"
  content    = azurerm_kubernetes_cluster.kubernetes.kube_admin_config_raw
  depends_on = [azurerm_kubernetes_cluster.kubernetes]
}
