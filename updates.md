# FarmVibes.AI AKS Deployment on Azure Government Cloud

## Summary of Changes

### 1. AzureRM Terraform Provider Updated (3.89.0 → 3.116.0)

The original provider version used a preview API (`2023-04-02-preview`) for AKS that isn't available in Azure Gov cloud.

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/infra/providers.tf`
- `src/vibe_core/vibe_core/terraform/aks/modules/rg/providers.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/infra/providers.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/rg/providers.tf`

### 2. Application Insights Updated to Workspace-Based

Classic Application Insights (without `workspace_id`) was deprecated in Feb 2024.  
Added `workspace_id` to link App Insights to the Log Analytics workspace.  
Also removed deprecated `retention_policy` blocks from the diagnostic setting.

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/infra/azure_monitor.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/infra/azure_monitor.tf`

### 3. VM Sizes Updated for Gov Cloud

`Standard_B4ms` and `Standard_D8s_v3` are not available in the Gov cloud subscription.  
Replaced with equivalent sizes from the allowed list.

| Node Pool | Old VM Size       | New VM Size        |
|-----------|-------------------|--------------------|
| Default   | Standard_B4ms     | Standard_D4as_v6   |
| Worker    | Standard_D8s_v3   | Standard_D8as_v6   |

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/infra/kubernetes.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/infra/kubernetes.tf`

### 4. Helm Provider Pinned to <3.0.0

Helm provider v3.x introduced a breaking change — the `kubernetes` block inside the `helm` provider was replaced with a new syntax. The existing Terraform configs use `load_config_file = true` and the old `kubernetes {}` block, which is incompatible with v3.x. Pinned to `>=2.7.1, <3.0.0`.

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/kubernetes/providers.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/kubernetes/providers.tf`

### 5. Dapr `needs_upgrade()` Patched for Fresh Installs

The `DaprWrapper.needs_upgrade()` method calls `dapr status -k` to get the current Dapr version. On a fresh cluster where Dapr isn't installed yet, this command fails, causing the entire `update` flow to abort before Terraform can install Dapr.

Wrapped the method body in a `try/except` that returns `False` when Dapr is not yet present, allowing Terraform to proceed with the installation.

**Files changed:**
- `src/vibe_core/vibe_core/cli/wrappers.py` (line ~1757)
- `.venv/Lib/site-packages/vibe_core/cli/wrappers.py` (line ~1757)

### 7. NGINX Ingress Chart Switched to Community Chart

The original config used the NGINX Inc chart (`https://helm.nginx.com/stable` / `nginx-ingress` v0.16.0), which:
- Required a repo cache that wasn't present locally (Helm was looking for a `scubakiz-index.yaml` file)
- Was incompatible with Kubernetes v1.33.6

Switched to the community `ingress-nginx` chart from `https://kubernetes.github.io/ingress-nginx` at version `4.14.3` (app version 1.14.3), which is actively maintained and K8s 1.33 compatible.

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/kubernetes/init.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/kubernetes/init.tf`

### 8. RabbitMQ Image Tag Removed and Timeout Added

The RabbitMQ Helm release was pinned to `image.tag = "3.10.8-debian-11-r4"` — an EOL version no longer available in the Bitnami registry. The chart (v16.0.14) defaults to RabbitMQ 4.1.3, which works fine.

- Removed the `image.tag` override so the chart uses its default image
- Added `timeout = 600` (was using the 300s default, which wasn't enough)
- Uninstalled the failed Helm release from the cluster before retrying: `helm uninstall rabbitmq --namespace default`

**Files changed:**
- `src/vibe_core/vibe_core/terraform/aks/modules/kubernetes/rabbitmq.tf`
- `.venv/Lib/site-packages/vibe_core/terraform/aks/modules/kubernetes/rabbitmq.tf`

### 9. `.venv/` Added to .gitignore

---

## Commands Used

### Environment Setup

```powershell
# Create and activate virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install vibe_core package (provides farmvibes-ai CLI)
pip install ./src/vibe_core

# Fix missing pkg_resources (setuptools 82+ removed it)
pip install "setuptools<71"
```

### Azure Login (Gov Cloud)

```powershell
# Set cloud to Azure Government
az cloud set --name AzureUSGovernment
az login

# Verify correct subscription
az account show

# Switch subscription if needed
az account list
az account set --subscription <subscription-id>
```

### Register Azure Providers

```powershell
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Compute

# Check registration status
az provider show --namespace Microsoft.Network --query "registrationState"
```

### Fix Terminal Encoding (optional, for readable Terraform output)

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONUTF8 = "1"
chcp 65001
```

### Clean Up Before Fresh Install

```powershell
# Delete Azure resource group (if starting over)
az group delete --name farmvibes-rg --yes

# Remove local Terraform cache and lock files
Remove-Item -Recurse -Path "$env:USERPROFILE\.config\farmvibes-ai" -ErrorAction SilentlyContinue
```

### Deploy AKS Cluster (Initial Setup)

```powershell
farmvibes-ai remote setup --region usgovvirginia --cert-email eldon.gormsen@microsoft.com --resource-group farmvibes-rg --environment usgovernment
```

### Update Existing Cluster (After Partial Deploy)

If `setup` fails partway through and the resource group/cluster already exist, use `update` to resume:

```powershell
farmvibes-ai remote update --region usgovvirginia --cert-email eldon.gormsen@microsoft.com --resource-group farmvibes-rg --environment usgovernment
```

### Verify Cluster Nodes

```powershell
kubectl get nodes --kubeconfig "$env:USERPROFILE\.config\farmvibes-ai\kubeconfig"
```

### Verify CLI Works

```powershell
farmvibes-ai remote -h
```

---

## Known Issues / Notes

- **setuptools 82+** removed `pkg_resources`. The codebase uses `import pkg_resources` in `osartifacts.py`. Pinning `setuptools<71` is the workaround.
- **VS Code Terraform extension** may show false errors (e.g., `enable_auto_scaling` not expected). This is because the extension validates against azurerm 4.x schema, but we're pinned to 3.116.0 where these attributes are still valid.
- **Pydantic v1** is used throughout (EOL June 2024). Migration to v2 is non-trivial and not needed for deployment.
- **Helm charts**: NGINX updated to community ingress-nginx 4.14.3. RabbitMQ using chart default (4.1.3). Dapr 1.13.3 and cert-manager 1.12.2 remain at original versions.
- **RabbitMQ image (SECURITY NOTE)**: Bitnami removed Debian-based images from `docker.io/bitnami` in late 2025, moving them to the `bitnamilegacy` registry. The RabbitMQ deployment currently pulls from `bitnamilegacy/rabbitmq` with `global.security.allowInsecureImages = true` to bypass the Bitnami chart's image verification. **This is a temporary workaround** — the `bitnamilegacy` images may not receive timely security patches. Upgrade to the current Photon-based `bitnami/rabbitmq` image with a matching chart version as soon as the cluster is stable (see Post-Deployment section).
- **CPU quotas** required: at least 20 Total Regional vCPUs, 12 Standard DSv3 (or equivalent for Dv6 family), 8 Standard BS family in usgovvirginia.

---

## Post-Deployment: Consider Updating

Items to revisit once the cluster is fully operational. These are non-blocking but improve security, supportability, and long-term maintenance.

### Helm Charts

| Chart | Current | Action |
|---|---|---|
| **RabbitMQ** | v16.0.14 (image from `bitnamilegacy`) | Upgrade chart to latest; switch image back to `bitnami/rabbitmq` Photon-based (e.g., 4.2.x). Chart and image versions should be upgraded together. |
| **Dapr** | 1.13.3 | Upgrade to latest 1.14.x+ for bug fixes and K8s 1.33 compatibility improvements |
| **cert-manager** | 1.12.2 | Upgrade to 1.16.x+ (1.12 is EOL) |
| **Redis** | Chart 25.3.2 / App 8.6.1 | Evaluate if current version meets needs; consider adding replicas for HA |

### Terraform Providers

| Provider | Current | Action |
|---|---|---|
| **azurerm** | 3.116.0 | Consider migrating to 4.x when ready (breaking changes — requires config updates) |
| **helm** | Pinned <3.0.0 | Update Terraform configs to support Helm provider 3.x syntax, then unpin |
| **kubernetes** | Uses deprecated `kubernetes_namespace` | Migrate to `kubernetes_namespace_v1` and other `_v1` resources |

### Application Code

| Item | Action |
|---|---|
| **Pydantic v1** | Migrate to Pydantic v2 (v1 EOL June 2024). Non-trivial — model syntax changes. |
| **setuptools / pkg_resources** | Replace `import pkg_resources` with `importlib.metadata` so modern setuptools works |
| **RabbitMQ image base** | Currently using `bitnamilegacy` Debian images. Move to Photon-based `bitnami/rabbitmq` with matching chart version. |

### Infrastructure

| Item | Action |
|---|---|
| **Redis HA** | Currently single master, 0 replicas. Add replicas or consider Azure Cache for Redis for production. |
| **RabbitMQ HA** | Single replica. Consider adding replicas or Azure Service Bus for production messaging. |
| **TLS / cert-manager** | Verify Let's Encrypt certs are issuing correctly after deployment. |
| **NGINX Ingress** | Validate ingress rules and load balancer health probes with the new community chart. |

### NGINX Ingress Retirement (CRITICAL)

The Kubernetes SIG Network [announced the retirement](https://www.kubernetes.dev/blog/2025/11/12/ingress-nginx-retirement/) of the `ingress-nginx` project in November 2025. **Community maintenance ended March 2026** — the chart we are currently using (community `ingress-nginx` 4.14.3) will receive no further updates.

**Impact**: The self-managed `ingress-nginx` Helm release in this cluster is now unsupported upstream. No new features, bug fixes, or security patches will be released.

**Microsoft's recommended migration paths** (in order of effort):

1. **AKS Application Routing add-on** (lowest effort) — Enable the managed NGINX ingress add-on built into AKS (`az aks approuting enable`). Microsoft will provide critical security patches through **November 2026**. Ingress annotations are largely compatible; main changes are removing the self-managed Helm release and switching `ingressClassName` from `nginx` to `webapprouting.kubernetes.azure.com/nginx`. This buys time to plan the long-term Gateway API migration.

2. **Application Gateway for Containers** (recommended long-term) — Azure-native L7 load balancer that supports both the Ingress API and the newer Gateway API. Best option for production workloads that need a fully supported, Azure-managed solution beyond November 2026.

3. **Istio service mesh add-on** — If adopting a service mesh, the AKS Istio add-on provides ingress gateway capabilities with a path to Gateway API support.

**Action required**: Migrate off the self-managed `ingress-nginx` Helm chart. The shortest path is option 1 (Application Routing add-on), which requires:
- Enabling the add-on on the AKS cluster
- Updating the `kubernetes_ingress_v1` resource in `restapi.tf` (annotations and `ingressClassName`)
- Removing the `helm_release.nginx-ingress` resource from `init.tf`
- Removing the `kubernetes_namespace.kubernetesnginxnamespace` resource