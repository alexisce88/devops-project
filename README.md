# Proiect Capstone DevOps

Ecosistem CI/CD complet automatizat pentru o aplicație web pe 3 niveluri (React + Node.js/Express + PostgreSQL) pe AWS.

## Arhitectură

- **4 instanțe EC2 t3.small**: Monitoring, Staging, Blue (Producție), Green (Producție)
- **Bază de date**: RDS PostgreSQL 15 (partajată între Blue și Green)
- **Registry**: GitHub Container Registry (GHCR)
- **4 GitHub Actions Workflows**: CI, Staging, Producție (Blue/Green), Backup DB
- **Deployment Blue/Green** cu fereastră de monitorizare de 5 minute și rollback automat
- **Monitoring**: Prometheus + Grafana + Alertmanager + Blackbox Exporter
- **Backup zilnic**: pg_dump → S3
- **Terraform state**: stocat în S3

---

## Structura Proiectului

```
DevOps-Project/
├── app/
│   ├── frontend/                     # Aplicație React 18
│   ├── backend/                      # API Node.js/Express + PostgreSQL
│   ├── docker-compose.yml            # Dezvoltare locală
│   ├── docker-compose.staging.yml    # Staging (cu Postgres Docker)
│   └── docker-compose.production.yml # Producție (Blue/Green, cu RDS)
├── terraform/                        # Infrastructură AWS (IaC)
│   ├── main.tf                       # Module EC2, RDS
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf                   # Backend S3
│   └── modules/
│       ├── networking/               # VPC, subnets, IGW
│       ├── security_groups/          # Reguli firewall AWS
│       └── ec2/                      # Definiție instanțe EC2
├── ansible/
│   ├── playbooks/                    # Provizionare servere
│   │   ├── provision_staging.yml
│   │   ├── provision_production.yml
│   │   └── provision_monitoring.yml
│   ├── roles/
│   │   ├── common/                   # Docker, swap, Node Exporter
│   │   ├── nginx/                    # Nginx + configurații Blue/Green
│   │   └── monitoring/               # Stack monitoring (Docker Compose)
│   └── scripts/
│       └── update_inventory.sh       # Generare inventar din Terraform outputs
├── .github/workflows/
│   ├── ci.yml                        # Lint + teste la PR
│   ├── staging.yml                   # Build → Deploy → Teste integrare → Promovare
│   ├── production.yml                # Snapshot RDS → Deploy Blue/Green
│   └── db-backup.yml                 # Backup zilnic PostgreSQL → S3
├── monitoring/
│   ├── docker-compose.yml            # Prometheus, Grafana, Alertmanager, Blackbox
│   ├── prometheus/                   # Configurație scrape + reguli alertare
│   ├── alertmanager/                 # Rutare alerte
│   ├── grafana/                      # Dashboard-uri pre-configurate
│   └── blackbox/                     # Probe HTTP/TCP
├── nginx/conf.d/                     # Configurații Nginx de referință
├── scripts/
│   └── integration-tests.sh         # Teste de integrare bash (rulează pe staging live)
└── docs/                             # Documentație
```

---

## Pornire Rapidă

### 1. Infrastructură (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Completează terraform.tfvars cu: aws_region, key_pair_name, my_ip, db_password
terraform init
terraform apply
bash update-secrets.sh   # Trimite IP-urile și credențialele la GitHub Secrets
```

### 2. Generare Inventar Ansible

```bash
bash ansible/scripts/update_inventory.sh
# Citește automat IP-urile din Terraform outputs (publice + private)
```

### 3. Provizionare Servere

```bash
ansible-playbook ansible/playbooks/provision_staging.yml
ansible-playbook ansible/playbooks/provision_production.yml
GRAFANA_PASSWORD=parolatamana ansible-playbook ansible/playbooks/provision_monitoring.yml
```

### 4. Secrets GitHub Actions

Adaugă manual în Settings → Secrets → Actions:

| Secret | Descriere |
|--------|-----------|
| `STAGING_IP` | IP public server Staging |
| `PRODUCTION_IP` | IP public server Producție |
| `MONITORING_IP` | IP public server Monitoring |
| `SSH_PRIVATE_KEY` | Cheie privată SSH pentru EC2 |
| `DB_PASSWORD` | Parolă PostgreSQL |
| `DB_USERNAME` | Utilizator PostgreSQL (implicit: `appuser`) |
| `RDS_ENDPOINT` | Endpoint RDS (producție) |
| `AWS_ACCESS_KEY_ID` | Credențiale AWS pentru snapshot RDS + backup S3 |
| `AWS_SECRET_ACCESS_KEY` | Credențiale AWS |
| `AWS_REGION` | Regiunea AWS (ex: `eu-west-1`) |

> `STAGING_IP`, `PRODUCTION_IP`, `MONITORING_IP`, `RDS_ENDPOINT` și `AWS_REGION` sunt trimise automat de `terraform/update-secrets.sh` după `terraform apply`.

---

## Pipeline-uri

### Pipeline 1 — CI (Integrare Continuă)
**Declanșator:** Pull Request către `master`

```
PR deschis → lint backend + frontend
           → teste unitare backend + frontend
           → dacă eșuează: comentariu automat pe PR
```

### Pipeline 2 — Staging (Deployment Continuu)
**Declanșator:** Push/merge pe `master`

```
push master → build imagine Docker backend + frontend
            → tag cu commit SHA + push la GHCR
            → deploy pe serverul Staging
            → health check
            → teste de integrare (6 teste bash pe serverul live)
            → dacă toate trec: declanșează Pipeline 3
```

### Pipeline 3 — Producție (Blue/Green)
**Declanșator:** Manual (workflow_dispatch) sau automat din Pipeline 2

```
snapshot RDS ──┐
copy compose ──┤→ pull imagini → pornire sloturi → smoke test → switch Nginx → monitorizare 5 min
prepare ───────┘

- Smoke test eșuat   → oprire slot idle, abort
- Monitorizare OK    → actualizare /opt/bluegreen_state
- Monitorizare eșuat → rollback Nginx la slotul anterior
```

### Pipeline 4 — Backup Zilnic DB
**Declanșator:** Zilnic la 02:00 UTC (sau manual)

```
SSH → staging server → docker run pg_dump → gzip → upload S3
→ ștergere backup-uri mai vechi de 30 zile
```

---

## Monitoring

| Serviciu | Port | Descriere |
|----------|------|-----------|
| Grafana | 3000 | Dashboard-uri vizuale |
| Prometheus | 9090 | Colectare metrici |
| Alertmanager | 9093 | Rutare alerte |
| Blackbox Exporter | 9115 | Probe HTTP/TCP |
| Node Exporter | 9100 | Metrici OS (pe toate serverele) |

Accesează Grafana: `http://<MONITORING_IP>:3000`

---

## Tehnologii Utilizate

| Categorie | Tehnologie |
|-----------|-----------|
| Cloud | AWS (EC2, RDS, S3, VPC) |
| IaC | Terraform 1.6+ |
| Config Management | Ansible |
| CI/CD | GitHub Actions |
| Containerizare | Docker, Docker Compose |
| Registry | GitHub Container Registry (GHCR) |
| Frontend | React 18 |
| Backend | Node.js 20, Express 4 |
| Bază de date | PostgreSQL 15 |
| Web Server | Nginx 1.25 |
| Monitoring | Prometheus, Grafana, Alertmanager, Blackbox Exporter |
| Backup | pg_dump → AWS S3 |
