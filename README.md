# DevOps Capstone Project

CI/CD ecosystem for a 3-tier web app (React + Node.js/Express + PostgreSQL) on AWS.

## Architecture

- **5 EC2 t3.small instances**: Jenkins, Staging, Blue, Green, Monitoring
- **3 Jenkins Pipelines**: CI (lint+test), Staging (build+deploy), Production (Blue/Green)
- **Blue/Green deployment** with 10-minute monitoring window and auto-rollback
- **Self-healing**: Prometheus AppDown alert → Alertmanager → Jenkins rollback

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
bash ansible/scripts/update_inventory.sh
```

### 3. Provision All Servers

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### 4. Jenkins Setup

1. Access Jenkins at `http://JENKINS_IP:8080`
2. Add credentials (see `jenkins/pipelines/ci/Jenkinsfile` for required credential IDs)
3. Create Multibranch Pipeline pointing to this repo
4. Add GitHub webhook: `http://JENKINS_IP:8080/github-webhook/`

## Project Structure

```
DevOps-Project/
├── app/frontend/          # React app
├── app/backend/           # Express API
├── terraform/             # AWS infrastructure
├── ansible/               # Server configuration + deployment
├── jenkins/               # Jenkinsfiles + shared library
├── nginx/                 # Nginx configs (reference)
├── monitoring/            # Prometheus + Grafana + Alertmanager
└── docs/                  # Romanian PDF documentation
```

## Credentials Required in Jenkins

| ID | Type | Purpose |
|---|---|---|
| `github-token` | Secret Text | GitHub PAT (repo + write:packages) |
| `ghcr-creds` | Username+Password | Docker login to ghcr.io |
| `ec2-ssh-key` | SSH Private Key | Ansible SSH to EC2 instances |
| `staging-server-ip` | Secret Text | Staging EC2 IP |
| `blue-server-ip` | Secret Text | Blue EC2 IP |
| `green-server-ip` | Secret Text | Green EC2 IP |
| `nginx-server-ip` | Secret Text | Jenkins/Nginx server IP |

## Pipelines

| Pipeline | Trigger | Action |
|---|---|---|
| CI | PR / push | Lint + test + GitHub status |
| Staging | Merge to main | Build → Push GHCR → Deploy → Integration tests |
| Production | Manual / alert | Blue/Green deploy → smoke test → switch → monitor |
