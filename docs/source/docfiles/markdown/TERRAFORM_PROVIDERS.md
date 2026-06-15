# Terraform Provider Matrix

FarmVibes.AI keeps provider upgrades staged because remote deployments can run in Azure Government, where some public Azure API versions are unavailable. Upgrade one provider family at a time and verify a Terraform plan before applying to a live cluster.

## Current Baseline

| Scope | Provider | Constraint | Notes |
|---|---|---|---|
| AKS resource group | `hashicorp/azurerm` | `3.116.0` | Keeps the AzureRM 3.x AKS behavior that works in Azure Government. |
| AKS infrastructure | `hashicorp/azurerm` | `3.116.0` | Used for AKS, Key Vault, Storage, Cosmos DB, Log Analytics, Application Insights, and diagnostics. |
| AKS infrastructure | `hashicorp/random` | `3.1.0` | Used for deterministic suffixes. |
| AKS Kubernetes module | `hashicorp/kubernetes` | `>=2.16.0` | Some resources still use legacy names such as `kubernetes_namespace`. |
| AKS Kubernetes module | `hashicorp/helm` | `>=2.7.1, <3.0.0` | Required until `helm_release` `set {}` blocks are migrated to Helm provider v3 list syntax. |
| AKS Kubernetes module | `gavinbunney/kubectl` | `>=1.7.0` | Used for CRDs and custom resources. |
| Local Kubernetes module | `hashicorp/kubernetes` | `>=2.16.0` | Mirrors the Kubernetes resource style used by AKS. |
| Local Kubernetes module | `hashicorp/helm` | `>=2.7.1, <3.0.0` | Pinned below v3 for the same `helm_release` syntax reason. |
| Local Kubernetes module | `gavinbunney/kubectl` | `>=1.7.0` | Used for Dapr components. |
| Services module | `hashicorp/kubernetes` | `>=2.16.0` | Deploys FarmVibes services and ingress. |
| Services module | `hashicorp/helm` | `>=2.7.1, <3.0.0` | Kept aligned with other modules even though services currently do not install charts. |
| Services module | `gavinbunney/kubectl` | `>=1.7.0` | Kept aligned with the Kubernetes modules. |

## Upgrade Order

1. Stay on AzureRM 3.x until a no-op plan is confirmed in Azure Government.
2. Migrate Kubernetes provider resources to `_v1` variants with Terraform state moves or `moved` blocks.
3. Migrate Helm provider syntax to v3 by converting provider nested blocks and every `helm_release` `set`, `set_list`, and `set_sensitive` block to list attributes.
4. Prototype AzureRM 4.x in a disposable Azure Government resource group before changing production deployments.

## Validation Commands

Run validation from the module being changed. For deployed clusters, prefer the copied Terraform directory under the FarmVibes config directory because the CLI deploys from that copy.

```bash
terraform init -upgrade
terraform providers
terraform validate
terraform plan
```

For source-only validation, the following modules can be checked independently:

```bash
terraform -chdir=src/vibe_core/vibe_core/terraform/aks/modules/infra init -backend=false
terraform -chdir=src/vibe_core/vibe_core/terraform/aks/modules/infra validate
terraform -chdir=src/vibe_core/vibe_core/terraform/aks/modules/kubernetes init -backend=false
terraform -chdir=src/vibe_core/vibe_core/terraform/aks/modules/kubernetes validate
terraform -chdir=src/vibe_core/vibe_core/terraform/local/modules/kubernetes init -backend=false
terraform -chdir=src/vibe_core/vibe_core/terraform/local/modules/kubernetes validate
```

Do not treat VS Code Terraform extension diagnostics alone as authoritative when it validates against AzureRM 4.x while the repo is pinned to AzureRM 3.116.0.