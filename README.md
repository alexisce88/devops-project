# DevOps Capstone Project

CI/CD ecosystem for a 3-tier web app (React + Node.js/Express + PostgreSQL) on AWS.

## Architecture

- **3 EC2 t3.small instances**: Monitoring, Staging, Production
- **3 GitHub Actions Workflows**: CI (lint+test), Staging (build+deploy), Production (Blue/Green)
- **Blue/Green deployment** with 5-minute monitoring window and auto-rollback
- **Self-healing**: Prometheus AppDown alert → Alertmanager (extendable to notify/trigger workflows)

## Quick Start

### 1. Infrastructure (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS region, key pair name, and IP
terraform init
terraform apply
```

### 2. Populate Ansible Inventory

```bash
MONITORING_IP=<your-monitoring-server-ip> bash ansible/scripts/update_inventory.sh
```

### 3. Provision All Servers

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### 4. GitHub Actions Setup

Add the following secrets to your GitHub repository (Settings → Secrets):

| Secret | Purpose |
|--------|---------|
| `STAGING_IP` | Staging EC2 public IP |
| `PRODUCTION_IP` | Production EC2 public IP |
| `SSH_PRIVATE_KEY` | Private key for SSH access to EC2 instances |
| `DB_PASSWORD` | PostgreSQL password |
| `RDS_ENDPOINT` | RDS endpoint (production only) |

## Project Structure

```
DevOps-Project/
├── app/frontend/          # React app
├── app/backend/           # Express API
├── terraform/             # AWS infrastructure
├── ansible/               # Server configuration + deployment
├── .github/workflows/     # GitHub Actions CI/CD pipelines
├── nginx/                 # Nginx configs (reference)
├── monitoring/            # Prometheus + Grafana + Alertmanager
└── docs/                  # Romanian PDF documentation
```

## Pipelines

| Workflow | Trigger | Action |
|---|---|---|
| CI | PR to master | Lint + test (backend + frontend) |
| Staging | Push to master | Build → Push GHCR → Deploy → Health check |
| Production | Manual dispatch | Blue/Green deploy → smoke test → switch → 5-min monitor |
