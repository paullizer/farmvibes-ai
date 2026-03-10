1. Critical Vulnerability: pgx (CVE‑2024‑27304) ✅ BOD 22‑01
Goal: Ensure no running container is built with github.com/jackc/pgx/v5 < 5.5.4.
Verify

 Identify which images include pgx (likely Dapr sidecars / app images)

Confirm via:

Dockerfile
go.mod / go.sum
go list -m all | grep pgx




 Confirm pgx version ≥ 5.5.4 after rebuild
 Confirm Dapr version upgrade pulls fixed pgx transitively

Target: Dapr ≥ 1.16.x



Remediate

 Update Dapr from 1.13.3 → 1.16.2
 Rebuild all affected images
 Redeploy Dapr components
 Validate Orca alert clears for pgx CVE


2. Golang x/net Vulnerability (cert-manager)
Goal: Remove golang.org/x/net 0.10.0
Verify

 Identify cert-manager image in use:

quay.io/jetstack/cert-manager-controller


 Confirm cert-manager version ≥ 1.19.1
 Verify no older cert-manager pods still running

Remediate

 Upgrade cert-manager 1.12.2 → 1.19.1
 Redeploy CRDs if required
 Confirm TLS renewal resumes successfully


3. Bitnami Image Deprecation (ImagePullBackOff)
Goal: Eliminate reliance on deprecated Bitnami free registry
RabbitMQ

 Locate RabbitMQ image references (Terraform / Helm)
 Replace:

❌ docker.io/bitnami/rabbitmq
✅ docker.io/bitnamilegacy/rabbitmq


 Confirm image tag exists (no NotFound)

Redis

 Replace:

❌ docker.io/bitnami/redis
✅ docker.io/bitnamisecure/redis


 Confirm image pull succeeds

Verify

 No pods in ImagePullBackOff
 Orca no longer flags missing images


4. Redis Stability & Capacity Issues
Goal: Stop Redis OOM / CrashLoopBackOff
Verify

 Current Redis deployment type:

In‑cluster Bitnami Redis vs Azure Cache for Redis


 Confirm Redis memory limits & eviction policy
 Check number of cached jobs (~900+ observed)

Short‑Term Fix

 Confirm PVC deletion was only temporary
 Identify stuck jobs holding cache references
 Force delete stuck jobs if needed

Long‑Term Fix (Preferred)

 Switch cache to Azure Managed Redis
 Update cache_metadata_store.py:

Replace local Redis connection with external Redis


 Update secret with Azure Redis connection string
 Rebuild vibe_agent image
 Disable in‑cluster Redis deployment only if safe


5. Terraform / Provider Compatibility (US Gov)
Goal: Use supported ARM APIs in USGov
Verify

 AzureRM provider version ≥ 3.117.0
 No usage of 2023‑04‑02‑preview APIs
 Changes applied in:

infra/providers.tf
rg/providers.tf



Confirm

 Terraform plan/apply succeeds
 No Gov cloud API rejection errors


6. Dapr Deployment & RBAC Issues (Blocking)
Goal: Restore Dapr functionality
Verify

 Dapr components deployed:

dapr-operator
dapr-sentry
dapr-placement
dapr-injector


 Dapr CLI version matches cluster version
 User/service principal has permissions to:

list pods at cluster scope



Remediate

 Confirm AKS RBAC:

Azure RBAC vs Kubernetes RBAC


 Assign appropriate role:

Azure Kubernetes Service RBAC Cluster Admin


 Re‑run:

dapr status -k


 Validate sidecar injection works


7. AKS Public API Lockdown (FedRAMP / Secure Score)
Goal: Restrict AKS API to FS CIDR ranges
Verify

 AKS API server authorized IP ranges set
 No 0.0.0.0/0 access
 kubectl access only possible from:

FS PN
FS office network



Confirm

 Secure Score improves
 CIO sign‑off


8. Certificates / TLS Renewal
Goal: Ensure cert-manager renews automatically
Verify

 cert-manager pods healthy
 ClusterIssuer / Issuer valid
 Certificates not expired
 Renewal events observed


9. FarmVibes Functional Health
Goal: Platform usable after remediation
Verify

 FarmVibes API reachable
 Dashboard loads
 Dapr sidecars attached
 Data‑ops agent can read/write cache
 Jobs no longer pile up indefinitely


10. Evidence for Security / CIO
Goal: Close BOD 22‑01 cleanly
Capture

 Updated image versions
 Dapr version
 cert-manager version
 Redis architecture decision
 AKS API IP restriction config
 Orca alert cleared screenshots


TL;DR – Highest Risk Items
If you only verify five things first, make it these:

✅ pgx ≥ 5.5.4 (via Dapr 1.16.x)
✅ cert-manager ≥ 1.19.1
✅ No Bitnami free images remaining
✅ AKS API locked to FS CIDRs
✅ Redis no longer OOM / crashlooping

If you want, next I can:

Turn this into a security remediation tracker
Map items directly to Orca findings
Create a “what changed” summary for CIO