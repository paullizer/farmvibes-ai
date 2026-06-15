# AKS Operational Readiness

This guide covers the first operational checks and recovery steps for a remote FarmVibes.AI AKS deployment.

## Enable Telemetry and Alerts

Remote deployments create a Log Analytics workspace, workspace-based Application Insights resource, OpenTelemetry collector, AKS diagnostics, and Container Insights when telemetry is enabled.

To notify operators, create or reuse an Azure Monitor Action Group, then pass its resource ID during setup or update:

```bash
farmvibes-ai remote update \
  --enable-telemetry \
  --monitor-action-group-ids "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/microsoft.insights/actionGroups/<action-group-name>" \
  --region <region> \
  --cert-email <email>
```

Use a comma-separated list for multiple Action Groups. Alert rules are not created when `--monitor-action-group-ids` is empty.

The default alert set checks:

- AKS nodes that are not Ready.
- Containers stuck in `ImagePullBackOff`, `ErrImagePull`, or `CrashLoopBackOff`.
- FarmVibes service pods that are not running.
- Redis, RabbitMQ, Dapr, cert-manager, and ingress pods that are not running.
- cert-manager renewal, order, or challenge errors.
- OpenTelemetry collector export errors.

High-volume AKS audit logs are excluded from diagnostic settings by default. To collect them, override `aks_diagnostic_log_category_exclusions` in Terraform.

## Validate Azure Government Telemetry

For Azure Government deployments, confirm the collector exports to the ingestion endpoint from the Application Insights connection string rather than a public Azure endpoint.

```bash
az monitor app-insights component show \
  --resource-group <resource-group> \
  --app <application-insights-name> \
  --query connectionString

kubectl get configmap otel-collector-conf -n default -o yaml \
  --kubeconfig ~/.config/farmvibes-ai/kubeconfig

kubectl logs deploy/otel-collector -n default --tail=200 \
  --kubeconfig ~/.config/farmvibes-ai/kubeconfig
```

In Azure Government, the Application Insights connection string should include a government cloud ingestion endpoint. The collector logs should not show repeated `azuremonitor`, `export`, authentication, or DNS failures.

Use the Log Analytics workspace to confirm Kubernetes data is flowing:

```kusto
KubePodInventory
| where TimeGenerated > ago(30m)
| summarize count() by Namespace
```

## Triage Commands

Set the namespace as needed. Most FarmVibes services run in `default`, Dapr runs in `dapr-system`, and cert-manager runs in `cert-manager`.

```bash
kubectl get nodes -o wide --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl get pods -A --sort-by=.metadata.creationTimestamp --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl describe pod <pod-name> -n <namespace> --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl logs <pod-name> -n <namespace> --all-containers --tail=200 --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl get events -A --sort-by=.lastTimestamp --kubeconfig ~/.config/farmvibes-ai/kubeconfig
```

## Redis Full or OOM

Symptoms include Redis pod restarts, workflow metadata failures, or pods pending because the Redis volume is under pressure.

1. Check pod state and recent events.

   ```bash
   kubectl get pods -n default -l app.kubernetes.io/name=redis --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   kubectl describe pod -n default -l app.kubernetes.io/name=redis --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   ```

2. Check Redis memory and key count.

   ```bash
   kubectl --kubeconfig ~/.config/farmvibes-ai/kubeconfig exec -n default pod/redis-master-0 -- redis-cli INFO memory
   kubectl --kubeconfig ~/.config/farmvibes-ai/kubeconfig exec -n default pod/redis-master-0 -- redis-cli DBSIZE
   ```

3. If metadata keys are growing too quickly, set a lower `redis_metadata_ttl_seconds` value and run `farmvibes-ai remote update`.

4. If the dataset is expected to be large, increase the Redis memory or persistence settings in Terraform and update the cluster.

## RabbitMQ Backlog or Image Pull Failure

Symptoms include worker pods idle while workflows queue, RabbitMQ pods restarting, or `ImagePullBackOff` after a chart update.

1. Inspect pod and image pull state.

   ```bash
   kubectl get pods -n default -l app.kubernetes.io/name=rabbitmq --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   kubectl describe pod -n default -l app.kubernetes.io/name=rabbitmq --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   ```

2. Check queues from the RabbitMQ container.

   ```bash
   kubectl --kubeconfig ~/.config/farmvibes-ai/kubeconfig exec -n default pod/rabbitmq-0 -- rabbitmqctl list_queues name messages messages_unacknowledged
   ```

3. If the image cannot be pulled, verify the chart image tag in Terraform and run `farmvibes-ai remote update` after correcting the value.

4. If queues are growing, scale FarmVibes workers within the configured node capacity or investigate worker pod logs for processing errors.

## Failed Certificate Renewal

Symptoms include browser TLS errors, expired certificates, failed ACME challenges, or cert-manager alert noise.

```bash
kubectl get certificate,certificaterequest,order,challenge -A --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl logs deploy/cert-manager -n cert-manager --tail=200 --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl describe ingress terravibes-rest-api-ingress -n default --kubeconfig ~/.config/farmvibes-ai/kubeconfig
```

Confirm the ingress class matches the selected ingress controller and that the public DNS name resolves to the active ingress IP. After fixing DNS or ingress, delete the failed ACME order or challenge and let cert-manager recreate it.

## Ingress Cutover or Rollback

FarmVibes supports either the self-managed NGINX ingress release or AKS Application Routing.

1. Check the active ingress class and address.

   ```bash
   kubectl get ingressclass --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   kubectl get ingress terravibes-rest-api-ingress -n default -o wide --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   ```

2. For Application Routing, verify the managed controller exists.

   ```bash
   kubectl get nginxingresscontrollers -A --kubeconfig ~/.config/farmvibes-ai/kubeconfig
   ```

3. Roll forward or back by rerunning `farmvibes-ai remote update` with `--ingress-controller-type application_routing` or `--ingress-controller-type self_managed_nginx`.

4. Recheck DNS, ingress address, and certificate status after the update.

## Dapr Sidecar or Control Plane Failure

Symptoms include FarmVibes services running without sidecars, workflow messaging failures, or Dapr pods restarting.

```bash
kubectl get pods -n dapr-system --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl get pods -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.dapr\.io/enabled}{"\n"}{end}' --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl logs -n dapr-system deploy/dapr-operator --tail=200 --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl logs -n default <farmvibes-pod-name> -c daprd --tail=200 --kubeconfig ~/.config/farmvibes-ai/kubeconfig
```

If the Dapr control plane is healthy but sidecars are missing, restart the FarmVibes deployments. If the control plane is unhealthy after an update, rerun `farmvibes-ai remote update` so Terraform and the Dapr CRDs converge.

## AKS Node Pool Scale Failure

Symptoms include pods stuck Pending, nodes NotReady, failed scale events, or Azure quota errors.

```bash
kubectl get nodes -o wide --kubeconfig ~/.config/farmvibes-ai/kubeconfig
kubectl describe nodes --kubeconfig ~/.config/farmvibes-ai/kubeconfig
az aks show --resource-group <resource-group> --name <cluster-name> --query agentPoolProfiles
az vm list-usage --location <region> --output table
```

Check regional vCPU quota, VM family quota, subnet IP capacity, and node OS image availability. After quota or subnet issues are fixed, rerun `farmvibes-ai remote update`.

## Reinstall the CLI From Source

If Terraform or CLI changes are made from source, reinstall the CLI before running setup or update commands.

```bash
pip uninstall -y vibe-core
pip install -e ./src/vibe_core
farmvibes-ai remote status --resource-group <resource-group> --cluster-name <cluster-name> --environment <environment>
```

Run the command from the repository root so the editable install points to the local source tree.