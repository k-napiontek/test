# AWS EKS Production Platform

## Architecture

GitOps pipeline with automated dev deployments and gated stg/prod promotions.

```
Developer → main branch → Semantic Release (tag) → Build Images → dev ECR
  → ArgoCD Image Updater → DEV auto-deploy
  → promote.yaml (manual) → stg ECR → ArgoCD → STG
  → promote.yaml (manual) → prod ECR → ArgoCD → PROD
```

## Quick Start

```bash
aws eks update-kubeconfig --region=eu-central-1 --name dev-myapp
```

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci-backend.yaml` | PR (backend changes) | Go lint (golangci-lint) |
| `ci-frontend.yaml` | PR (frontend changes) | ESLint, Vitest, Trivy scan |
| `release.yaml` | Push to main | Semantic Release → tag + GitHub Release |
| `build-images.yaml` | Tag `v*.*.*` | Build backend + frontend → dev ECR |
| `promote.yaml` | Manual dispatch | Copy images to stg/prod ECR, update overlays |

## Promoting a Release

1. Go to **Actions** → **Promote Release** → **Run workflow**
2. Enter version (e.g., `v1.3.0`), target env (`stg` or `prod`), services
3. Approve via GitHub Environment protection rules
4. ArgoCD auto-syncs the target environment

## GitHub Environments Setup (Manual)

Configure in **Settings → Environments**:

| Environment | Protection Rules |
|-------------|-----------------|
| `dev` | None (auto-deploy via Image Updater) |
| `stg` | Required reviewers: 1-2 people |
| `prod` | Required reviewers: 2+ people, Wait timer: 30 min, Deployment branches: `main` only |

## Multi-Cluster Setup (Future)

When stg/prod clusters are provisioned:

1. Register clusters: `argocd cluster add <context-name>`
2. Update `destination.server` in ArgoCD apps (`04-gitops-apps/apps/*-stg-app.yaml`, `*-prod-app.yaml`)
3. Configure ECR pull secrets on new clusters

## Project Structure

```
.github/workflows/       # CI/CD pipelines
01-terraform-infra/       # Infrastructure as Code (VPC, EKS, ArgoCD, ECR)
02-app-source-code/       # Backend (Go) + Frontend (React/Vite)
03-gitops-infra/          # ArgoCD infra apps (Image Updater, External Secrets, Monitoring)
04-gitops-apps/           # ArgoCD application definitions + Kustomize manifests
  apps/                   # ArgoCD Application CRDs (one per service per env)
  manifests/              # Kustomize base + overlays (dev/stg/prod)
```
