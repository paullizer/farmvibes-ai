# AKS Deployment Change List

This change list summarizes the deployment-related updates made to keep remote
FarmVibes.AI AKS deployments working in current Azure and Azure Government environments.
It is intended as an operator-facing companion to the [AKS setup guide](./AKS.md), not as
a complete product release note.

## Deployment Flow

- Added explicit remote AKS deployment guidance to the root README, including Azure public cloud
  and Azure Government examples.
- Documented `farmvibes-ai remote update` as the safe way to resume a partially completed remote
  deployment after the resource group or AKS cluster already exists.
- Updated the remote setup flow to refuse destructive setup against an existing cluster. Operators
  should use a dedicated resource group and use `remote update` to continue an interrupted deploy.
- Added CLI options for selecting Azure cloud environments and ingress mode, including
  `--environment usgovernment` and `--ingress-controller-type application_routing`.

## Azure And AKS Compatibility

- Pinned the AzureRM Terraform provider to `3.116.0`, avoiding newer provider behavior while still
  using an AKS API version available in Azure Government.
- Updated AKS node pools to use VM sizes available in the tested Azure Government subscription:
  `Standard_D4as_v6` for the default pool and `Standard_D8as_v6` for the worker pool.
- Added an AKS node OS SKU setting, defaulting to `Ubuntu`, so node pools avoid retired Azure Linux
  2 / Mariner images while the AzureRM provider remains pinned.
- Enabled managed Microsoft Entra ID / Azure RBAC for AKS administration and configured Terraform
  Kubernetes providers to authenticate through `kubelogin`.

## Ingress And Certificates

- Added support for AKS Application Routing as the preferred current ingress path. The default
  managed ingress class used by this path is `farmvibes-webapprouting`.
- Kept self-managed NGINX available as an option, but operators should treat it as a migration path,
  not the preferred long-term default.
- Updated cert-manager to use a configurable chart version, currently `v1.19.1`.
- Updated cert-manager chart settings for current releases: `crds.enabled`, `crds.keep`, Linux node
  selection, and disabled `startupapicheck.enabled` after the startup check job failed despite
  healthy cert-manager APIs.
- Updated ACME HTTP-01 handling so cert-manager can create a separate solver ingress instead of
  editing the Terraform-managed FarmVibes ingress in place.
- Disabled ingress-wide HTTPS redirect so the HTTP-01 solver path can be reached during certificate
  issuance. The FarmVibes service still publishes TLS on the reported HTTPS URL.

## Helm Charts And Images

- Pinned the Helm Terraform provider to `>=2.7.1, <3.0.0` because the current provider blocks use
  the Helm provider 2.x syntax.
- Updated Dapr runtime and chart defaults to `1.15.10`.
- Updated Redis image defaults to `7.4.1-debian-12-r2`.
- Updated RabbitMQ to chart `16.0.14` with image tag `4.1.3-debian-12-r1`.
- Overrode RabbitMQ image repository to `bitnamilegacy/rabbitmq` and enabled
  `global.security.allowInsecureImages=true` because `docker.io/bitnami/rabbitmq` no longer exposes
  the needed public Debian image tags. Treat this as a temporary compatibility workaround.
- Added a longer RabbitMQ Helm release timeout for AKS deployments.

## Telemetry And Operations

- Updated Azure Monitor/Application Insights wiring to use workspace-based Application Insights
  backed by Log Analytics.
- Added optional OpenTelemetry collector deployment and Azure Monitor exporter configuration when
  `--enable-telemetry` is used.
- Added optional Azure Monitor action group wiring for deployment alerts.
- Added AKS operational readiness documentation covering common recovery checks for pods, ingress,
  certificates, Dapr, telemetry, and node scaling.
- Added Terraform provider matrix documentation for pinned providers and future upgrade sequencing.

## Runtime Behavior Operators Should Know

- The remote FarmVibes endpoint exposes a REST API and Swagger documentation. It does not ship a
  separate web frontend.
- The root URL can return `404`; use `/docs`, `/v0/docs`, `/v1/docs`, `/v0/workflows`, or
  `/v1/workflows` on the reported service URL.
- The remote REST API is exposed on a public HTTPS endpoint by default and does not enforce
  application-layer authentication. Use controlled test deployments only unless network restrictions,
  an authenticated gateway, or another access control layer is added.

## Follow-Up Work

- Replace the temporary `bitnamilegacy/rabbitmq` image workaround with a current supported RabbitMQ
  chart and image pair.
- Plan a long-term ingress migration path. AKS Application Routing buys time, but production
  deployments should evaluate Application Gateway for Containers or another supported Gateway API
  path.
- Migrate Terraform provider configurations to support AzureRM 4.x and Helm provider 3.x when the
  deployment templates are ready for those breaking changes.
- Replace deprecated Kubernetes Terraform resources with their `_v1` equivalents.
- Replace `pkg_resources` usage with `importlib.metadata` so modern setuptools versions work
  without pinning.
- Plan the Pydantic v1 to v2 migration separately from deployment stabilization.