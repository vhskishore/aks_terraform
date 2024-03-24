resource "azurerm_resource_group" "rg" {
    name = var.resource_group_name
    location = var.location
}

resource "randon_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "akslogs" {
  name = "${var.logs_analytics_workspace_name}-${randon_id.log_analytics_workspace_name_suffix.dec}"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "akslogs" {
  solution_name = "ContainerInsights"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.akslogs.id
  workspace_name = azurerm_log_analytics_workspace.akslogs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name = var.cluster_name
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = var.dns_prefix

  default_node_pool {
    name = "agentpool"
    node_count = var.agent_count
    vm_size = "Standard_D2_v2"
  }

  service_principal {
    client_id = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin = "kubenet"
  }

  tags = {
    Environment = "Staging"
  }
}