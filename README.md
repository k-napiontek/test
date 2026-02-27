



# AWS EKS Production Platform

A production-grade Kubernetes platform on AWS demonstrating end-to-end GitOps delivery — from infrastructure provisioning through automated deployments to controlled production promotions. Built as a portfolio project to showcase real-world cloud engineering practices at scale.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Infrastructure Design](#infrastructure-design)
- [CI/CD Pipeline](#cicd-pipeline)
- [GitOps Workflow](#gitops-workflow)
- [Application Stack](#application-stack)
- [Design Decisions & Trade-offs](#design-decisions--trade-offs)
- [Challenges & Solutions](#challenges--solutions)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Environment Promotion](#environment-promotion)
- [Operational Runbook](#operational-runbook)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Actions CI/CD                        │
│                                                                    │
│  PR ──► Lint/Test/Scan ──► Merge ──► Semantic Release ──► Tag      │
│                                          │                         │
│                              ┌───────────┴───────────┐             │
│                              ▼                       ▼             │
│                     Build Images             Terraform Apply       │
│                     (to dev ECR)             (layered, gated)      │
└──────────────────────┬───────────────────────────────┬─────────────┘
                       │                               │
┌──────────────────────▼───────────────────────────────▼─────────────┐
│                          AWS (eu-central-1)                        │
│                                                                    │
│  ┌──────────┐   ┌──────────────────────────────────────────────┐   │
│  │   ECR    │   │              EKS Cluster                     │   │
│  │          │   │                                              │   │
│  │ dev-be   │◄──┤  ArgoCD ◄── Git repo (03-gitops, 04-gitops) │   │
│  │ dev-fe   │   │    │                                         │   │
│  │ stg-be   │   │    ├── Image Updater (watches ECR tags)      │   │
│  │ stg-fe   │   │    ├── External Secrets Operator             │   │
│  │ prod-be  │   │    └── Kube-Prometheus Stack                 │   │
│  │ prod-fe  │   │                                              │   │
│  └──────────┘   │  Namespaces: backend-dev, frontend-dev,      │   │
│                 │              backend-stg, frontend-stg,      │   │
│                 │              backend-prod, frontend-prod      │   │
│                 └──────────────────────────────────────────────┘   │
│                                                                    │
│  VPC (10.0.0.0/16) ── Public subnets (ALB) + Private subnets      │
│  KMS ── EKS secrets encryption with automatic key rotation        │
│  CloudWatch ── API, audit, and authenticator logs                  │
└────────────────────────────────────────────────────────────────────┘
```

The platform follows a layered, GitOps-driven architecture where infrastructure is provisioned declaratively through Terraform, applications are deployed through ArgoCD, and the entire lifecycle — from code commit to production — is automated with appropriate gates.

---

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Cloud** | AWS | — | VPC, EKS, ECR, IAM, KMS, CloudWatch |
| **IaC** | Terraform | >= 1.13 | Infrastructure provisioning via HCP Terraform |
| **Orchestration** | Kubernetes (EKS) | 1.34 | Container orchestration |
| **GitOps** | ArgoCD | 9.4.0 (Helm) | Declarative continuous delivery |
| **Image Automation** | ArgoCD Image Updater | 1.1.0 | Automated image tag updates from ECR |
| **Secrets** | External Secrets Operator | 2.0.0 | AWS Secrets Manager to K8s secrets |
| **Monitoring** | kube-prometheus-stack | 81.4.2 | Prometheus + Grafana observability |
| **CI/CD** | GitHub Actions | — | Build, test, release, promote |
| **Versioning** | semantic-release | — | Automated semver from conventional commits |
| **Backend** | Go | 1.25.6 | REST API with PostgreSQL and Prometheus metrics |
| **Frontend** | React + Vite | 19.2 / 7.3 | TypeScript SPA served via Nginx |
| **Container Builds** | Docker (multi-stage) | — | Minimal images (~10MB Go, ~50MB Nginx) |

---

## Infrastructure Design

### Layered Terraform Architecture

Infrastructure is split into isolated, dependency-ordered layers. Each layer is a separate HCP Terraform workspace with its own state, enabling independent lifecycle management and blast radius reduction.

```
Layer 00: Network          Layer 20: Compute          Layer 30: Bootstrap
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ VPC              │       │ EKS Cluster      │       │ ArgoCD (Helm)    │
│ Public Subnets   │──────►│ Managed Nodes    │──────►│ Root GitOps Apps │
│ Private Subnets  │ state │ EKS Addons       │ state │ Pod Identity     │
│ NAT Gateway      │  ref  │ KMS Encryption   │  ref  │ (Image Updater)  │
│ Internet Gateway │       │ CloudWatch Logs  │       │                  │
└──────────────────┘       └──────────────────┘       └──────────────────┘

Global: ECR (6 repos across dev/stg/prod × backend/frontend)
```

**Why layered?** Networking rarely changes, compute changes occasionally, and bootstrap (ArgoCD config) changes frequently. Separating them means a Helm chart upgrade doesn't risk your VPC, and a VPC CIDR change doesn't trigger a full cluster rebuild. Each layer reads outputs from its predecessor via `terraform_remote_state`.

### Network (Layer 00)

- **VPC**: `10.0.0.0/16` across 2 AZs (`eu-central-1a`, `eu-central-1b`)
- **Subnets**: Public (`10.0.101.0/24`, `10.0.102.0/24`) for ALB, private (`10.0.1.0/24`, `10.0.2.0/24`) for workloads
- **NAT Gateway**: Single in dev (cost optimization), multi-AZ ready for production
- **Kubernetes subnet tags**: Auto-discovery for AWS Load Balancer Controller

### Compute (Layer 20)

- **EKS**: Managed control plane with API and audit logging to CloudWatch
- **Nodes**: `c7i-flex.large` managed node group (2 desired, 1–4 scaling)
- **Addons**: vpc-cni, coredns, kube-proxy, eks-pod-identity-agent
- **Security**: KMS encryption for etcd secrets, IRSA and Pod Identity for workload IAM

### Bootstrap (Layer 30)

- **ArgoCD**: Installed via Helm with ALB Ingress
- **GitOps Root Apps**: Two `kubectl_manifest` resources bootstrap the app-of-apps pattern
- **Pod Identity**: IAM roles for Image Updater and ECR token refresher service accounts

### Global: ECR

Uses `setproduct()` to provision all 6 repositories (`{dev,stg,prod} × {backend,frontend}`) in a single module call with consistent lifecycle policies (retain last 30 tagged images). GitHub OIDC role enables keyless CI/CD authentication.

---

## CI/CD Pipeline

### End-to-End Flow

```
 ┌───────┐     ┌──────────┐     ┌─────────────────┐     ┌──────────────┐
 │  PR   │────►│ CI Checks│────►│  Merge to main   │────►│  Semantic    │
 │       │     │          │     │                  │     │  Release     │
 └───────┘     └──────────┘     └─────────────────┘     └──────┬───────┘
                                                               │
                                        creates tag v1.2.3     │
                                                               ▼
┌─────────────────┐     ┌──────────────┐     ┌─────────────────────────┐
│  Promote.yaml   │◄────│ Manual Gate  │     │  build-images.yaml      │
│  (stg / prod)   │     │ (approval)   │     │  Build & push to        │
│  crane copy +   │     └──────────────┘     │  dev ECR                │
│  kustomize edit │                          └────────────┬────────────┘
└────────┬────────┘                                       │
         │ updates overlay                                │ new tag in ECR
         ▼                                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ArgoCD (in-cluster)                              │
│                                                                    │
│  Image Updater ── detects new dev tags ── commits to Git           │
│  ArgoCD Sync ── deploys updated manifests to target namespace      │
└─────────────────────────────────────────────────────────────────────┘
```

### Workflow Summary

| Workflow | Trigger | What It Does |
|----------|---------|-------------|
| `ci-backend.yaml` | PR (backend changes) | `golangci-lint` on Go source |
| `ci-frontend.yaml` | PR (frontend changes) | ESLint + Vitest + Trivy vulnerability scan |
| `terraform.yaml` | PR / push (infra changes) | Plan on PR, apply on merge (layered, environment-gated) |
| `release.yaml` | Push to `main` | Conventional commit analysis → semver tag + GitHub Release |
| `build-images.yaml` | Tag `v*.*.*` | Multi-stage Docker build → push to dev ECR (OIDC auth) |
| `promote.yaml` | Manual dispatch | `crane copy` images to target env ECR + Kustomize overlay update |
| `drift-detection.yaml` | Daily cron (4 AM UTC) | `terraform plan -detailed-exitcode` across all workspaces |

### Terraform Apply Strategy

Terraform applies follow a cascading, environment-gated strategy:

1. **Global ECR** — auto-applied on merge (environment-independent)
2. **Dev** — auto-applied after global (no approval required)
3. **Staging** — applied after dev succeeds (requires reviewer approval)
4. **Production** — applied after staging succeeds (requires reviewer approval)

Within each environment, layers apply sequentially: `00-network` → `20-compute` → `30-bootstrap`.

---

## GitOps Workflow

### App-of-Apps Pattern

ArgoCD uses two root applications to manage the entire platform:

```
root-infra (03-gitops-infra/apps/)          root-apps (04-gitops-apps/apps/)
├── argocd-image-updater                    ├── backend-dev
├── external-secrets-operator               ├── backend-stg
└── monitoring (kube-prometheus-stack)       ├── backend-prod
                                            ├── frontend-dev
                                            ├── frontend-stg
                                            └── frontend-prod
```

Both root applications use recursive directory scanning with automated sync, pruning, and self-healing enabled — new apps are deployed simply by adding a YAML file to the appropriate directory.

### Kustomize Structure

Applications use a base/overlay pattern for environment differentiation:

```
manifests/backend/
├── base/
│   ├── kustomization.yaml      # Common resources
│   ├── deployment.yaml         # 2 replicas, health probes, resource limits
│   └── service.yaml            # ClusterIP on port 80
└── overlays/
    ├── dev/kustomization.yaml  # namespace: backend-dev, tag managed by Image Updater
    ├── stg/kustomization.yaml  # namespace: backend-stg, 2 replicas
    └── prod/kustomization.yaml # namespace: backend-prod, 3 replicas, higher resources
```

### Automated Image Updates (Dev)

ArgoCD Image Updater watches ECR for new semver tags and automatically commits updated image references back to Git:

1. `build-images.yaml` pushes `dev-myapp-backend:v1.2.3` to ECR
2. Image Updater detects the new tag via `pullsecret:argocd/ecr-pull-secret`
3. Image Updater commits the tag update to the overlay via `git:secret:argocd/github-creds`
4. ArgoCD detects the Git change and syncs the deployment

ECR tokens (12-hour expiry) are refreshed every 6 hours by a CronJob using EKS Pod Identity for keyless AWS authentication.

---

## Application Stack

### Backend (Go)

A REST API service demonstrating production patterns:

- **Endpoints**: `/health`, `/api/hello`, `/api/data` (CRUD to PostgreSQL), `/metrics` (Prometheus)
- **Observability**: Prometheus middleware tracking request count, latency histograms, and in-flight gauges
- **Security**: Read/Write/Idle timeouts, ReadHeaderTimeout (Slowloris protection), CORS middleware
- **Database**: PostgreSQL via `DATABASE_URL` environment variable
- **Container**: Multi-stage build → `scratch` base (~10MB final image)

### Frontend (React + TypeScript)

A Vite-powered SPA:

- **Stack**: React 19, TypeScript 5.9, Vite 7.3
- **Testing**: Vitest for unit tests, ESLint for code quality
- **Container**: Multi-stage build → `nginx:alpine` serving static assets (~50MB)
- **API Integration**: Form submission to backend `/api/data`

---

## Design Decisions & Trade-offs

### Why Layered Terraform over Monolith?

A monolithic Terraform root module is simpler but introduces dangerous coupling — a typo in a Helm values file could trigger a VPC replacement during plan. Layered architecture provides:
- **Blast radius isolation**: Bootstrap changes cannot affect networking
- **Independent apply cadence**: Network is stable for months, bootstrap changes weekly
- **Parallel team workflows**: Infra and platform teams can work on different layers
- **Faster plans**: Each workspace only evaluates its own resources

The trade-off is increased complexity in state references and a more involved CI/CD matrix.

### Why HCP Terraform over S3 Backend?

HCP Terraform provides remote execution (consistent environment), state locking, run history, and cost estimation out of the box. The remote execution model also means Terraform runs in a clean Linux environment — important for the `kubectl` and `helm` providers that need cluster credentials injected at runtime rather than relying on local kubeconfig.

### Why ArgoCD Image Updater over Flux?

ArgoCD was chosen as the GitOps engine for its mature UI, multi-tenancy model, and strong ecosystem. The Image Updater CRD-based approach (v2) provides a clean separation between image watching rules and application definitions. The write-back-to-Git strategy ensures the Git repository always reflects the running state.

### Why EKS Pod Identity over IRSA?

EKS Pod Identity (used for Image Updater and ECR token refresher) is the successor to IRSA with simpler setup — no OIDC provider annotation plumbing. IRSA is still used for the ALB Controller where the community module expects it. Both patterns eliminate static AWS credentials from the cluster.

### Why GitHub OIDC over IAM Access Keys?

All CI/CD AWS authentication uses OIDC federation — GitHub Actions assumes an IAM role via short-lived tokens. No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets to rotate or leak. The ECR module provisions the OIDC role alongside the repositories.

### Why `crane copy` for Promotion over Rebuild?

The `promote.yaml` workflow copies the exact image bytes from dev to staging/production ECR using `crane`. This guarantees binary-identical artifacts across environments — the image running in production is byte-for-byte the same as the one tested in dev, eliminating "works on my machine" class failures.

### Why Single NAT Gateway in Dev?

A NAT Gateway costs ~$32/month per AZ. In dev, a single NAT suffices. The module supports `single_nat_gateway = false` for staging and production where AZ resilience matters. This is a deliberate cost/resilience trade-off documented in the Terraform variables.

---

## Challenges & Solutions

### ECR Token Bootstrap Problem

**Problem**: ArgoCD Image Updater needs ECR credentials via a `docker-registry` secret, which is created by a CronJob running every 6 hours. On initial deployment, the secret doesn't exist yet, and Image Updater fails immediately.

**Solution**: Added a one-time Kubernetes Job (`ecr-token-init`) alongside the CronJob that runs on deployment and creates the initial secret. The Job uses `ttlSecondsAfterFinished: 300` for automatic cleanup.

### kubectl Provider Missing Configuration in HCP Terraform

**Problem**: The `alekc/kubectl` provider defaulted to `http://localhost` because it had no provider block — unlike the `helm` provider which was explicitly configured with EKS endpoint and token. In HCP Terraform's remote execution environment, there's no local kubeconfig to fall back on.

**Solution**: Added explicit `provider "kubectl"` block with `host`, `cluster_ca_certificate`, `token` from EKS data sources, and `load_config_file = false`.

### Semantic Release Tags Not Triggering Image Builds

**Problem**: `build-images.yaml` triggers on `push: tags: ['v*.*.*']`, and `release.yaml` creates tags via semantic-release. Tags and releases appeared in GitHub, but the build workflow never fired.

**Root Cause**: `actions/checkout@v4` defaults to the built-in `GITHUB_TOKEN` for git credentials. When semantic-release pushes a tag using this token, GitHub suppresses the resulting event to prevent recursive workflow loops — even though `secrets.PAT_TOKEN` was passed to semantic-release for API calls.

**Solution**: Pass `token: ${{ secrets.PAT_TOKEN }}` to `actions/checkout` so git push operations use the PAT, which is not subject to the anti-recursion filter.

### Multi-Environment ECR Repository Provisioning

**Problem**: Six ECR repositories (3 environments × 2 services) with identical configuration needed to be provisioned without code duplication.

**Solution**: Used Terraform's `setproduct()` function with `for_each` to generate all combinations from two lists (`["dev", "stg", "prod"]` and `["backend", "frontend"]`), producing a single module call that provisions all six repositories with consistent lifecycle policies and tagging.

---

## Project Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── ci-backend.yaml          # Go lint on PR
│   │   ├── ci-frontend.yaml         # ESLint + Vitest + Trivy on PR
│   │   ├── terraform.yaml           # Plan on PR, layered apply on merge
│   │   ├── release.yaml             # Semantic versioning + GitHub Release
│   │   ├── build-images.yaml        # Docker build → dev ECR on tag
│   │   ├── promote.yaml             # Image promotion to stg/prod
│   │   └── drift-detection.yaml     # Daily infrastructure drift check
│   ├── templates/
│   │   └── release-template.hbs     # Custom release notes template
│   └── utils/
│       └── file-filters.yaml        # Path-based workspace detection
│
├── 01-terraform-infra/
│   ├── modules/
│   │   ├── vpc/                     # VPC, subnets, NAT, IGW
│   │   ├── eks/                     # EKS cluster, node groups, addons
│   │   ├── alb/                     # ALB Controller IAM (IRSA)
│   │   ├── ecr/                     # ECR repos + GitHub OIDC role
│   │   └── argocd/                  # ArgoCD Helm + Pod Identity + root apps
│   ├── envs/dev/
│   │   ├── 00-network/              # VPC provisioning
│   │   ├── 20-compute/              # EKS cluster provisioning
│   │   └── 30-bootstrap/            # ArgoCD installation + GitOps init
│   └── global/ecr/                  # Cross-environment ECR repositories
│
├── 02-app-source-code/
│   ├── backend/                     # Go REST API (PostgreSQL + Prometheus)
│   └── frontend/                    # React + Vite + TypeScript SPA
│
├── 03-gitops-infra/
│   ├── root-infra.yaml              # Root app-of-apps for infrastructure
│   ├── apps/
│   │   ├── image-updater-app.yaml   # Image Updater + ECR token CronJob
│   │   ├── external-secrets.yaml    # External Secrets Operator
│   │   └── monitoring-app.yaml      # kube-prometheus-stack
│   └── manifests/
│       └── image-updater/           # Helm values for Image Updater
│
├── 04-gitops-apps/
│   ├── root-apps.yaml               # Root app-of-apps for workloads
│   ├── apps/                        # ArgoCD Application CRDs per service/env
│   └── manifests/                   # Kustomize base + overlays (dev/stg/prod)
│
└── .releaserc.js                    # Semantic-release configuration
```

---

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.13
- `kubectl` installed
- HCP Terraform account with organization `k-napiontek`
- GitHub PAT with `contents:write` scope (stored as `PAT_TOKEN` repository secret)

### Deploying Infrastructure

```bash
# 1. Global resources (ECR repositories)
terraform -chdir=01-terraform-infra/global/ecr init && terraform -chdir=01-terraform-infra/global/ecr apply

# 2. Networking
terraform -chdir=01-terraform-infra/envs/dev/00-network init && terraform -chdir=01-terraform-infra/envs/dev/00-network apply

# 3. EKS Cluster
terraform -chdir=01-terraform-infra/envs/dev/20-compute init && terraform -chdir=01-terraform-infra/envs/dev/20-compute apply

# 4. ArgoCD + GitOps Bootstrap
terraform -chdir=01-terraform-infra/envs/dev/30-bootstrap init && terraform -chdir=01-terraform-infra/envs/dev/30-bootstrap apply
```

### Connecting to the Cluster

```bash
aws eks update-kubeconfig --region eu-central-1 --name myapp
```

### Initial Secret Setup

After bootstrap, create the required secrets before Image Updater can operate:

```bash
# ECR pull credentials (or trigger the CronJob)
kubectl create job --from=cronjob/ecr-token-refresher ecr-initial-token -n argocd

# GitHub credentials for Image Updater write-back
kubectl create secret generic github-creds \
  -n argocd \
  --from-literal=username=<github-username> \
  --from-literal=password=<github-pat>
```

---

## Environment Promotion

### Dev (Automatic)

Every merge to `main` triggers semantic-release → tag → image build → Image Updater auto-deploys.

### Staging / Production (Manual, Gated)

1. Navigate to **Actions → Promote Release → Run workflow**
2. Specify the version tag (e.g., `v1.3.0`), target environment (`stg` or `prod`), and services
3. The workflow copies images via `crane` and updates Kustomize overlays
4. Approve via GitHub Environment protection rules
5. ArgoCD syncs the updated manifests automatically

| Environment | Protection Rules |
|-------------|-----------------|
| `dev` | None — fully automated via Image Updater |
| `stg` | Required reviewers (1–2 people) |
| `prod` | Required reviewers (2+), wait timer (30 min), `main` branch only |

---

## Operational Runbook

### Drift Detection

Runs daily at 4:00 AM UTC across all network and compute layers. Creates a GitHub Issue on detection. Manual trigger available via `workflow_dispatch`.

### ECR Token Rotation

The `ecr-token-refresher` CronJob runs every 6 hours (ECR tokens expire after 12). If Image Updater logs show `ecr-pull-secret not found`, trigger manually:

```bash
kubectl create job --from=cronjob/ecr-token-refresher ecr-refresh-$(date +%s) -n argocd
```

### ArgoCD Access

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward the UI
kubectl port-forward svc/my-argo-cd-argocd-server -n argocd 8080:443
```

---

## License

This project is part of a cloud engineering portfolio. See [LICENSE](LICENSE) for details.
