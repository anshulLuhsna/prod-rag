# 08 - Infrastructure & Deployment

## Overview

The system is deployed on Google Cloud Platform (GCP) using:
- Compute Engine for application hosting
- Cloud SQL for PostgreSQL
- Cloud Storage for document storage
- Docker Compose for container orchestration
- Terraform for infrastructure as code

---

## Architecture Diagram

```
                                    Internet
                                        │
                                        ▼
                              ┌─────────────────┐
                              │  Cloud DNS      │
                              │  (domain)       │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ Cloud Load      │
                              │ Balancer (HTTPS)│
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
┌───────────────────────────────────────────────────────────────────┐
│                        GCP VPC Network                             │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    Compute Engine VM                         │  │
│  │                    (e2-standard-4)                          │  │
│  │  ┌─────────────────────────────────────────────────────┐   │  │
│  │  │                  Docker Compose                      │   │  │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │   │  │
│  │  │  │ FastAPI │ │ Next.js │ │ Qdrant  │ │  Redis  │   │   │  │
│  │  │  │  :8000  │ │  :3000  │ │  :6333  │ │  :6379  │   │   │  │
│  │  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘   │   │  │
│  │  │  ┌─────────┐ ┌─────────┐                           │   │  │
│  │  │  │ Celery  │ │ Celery  │                           │   │  │
│  │  │  │ Worker  │ │  Beat   │                           │   │  │
│  │  │  └─────────┘ └─────────┘                           │   │  │
│  │  └─────────────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              │                                     │
│                              │ Private IP                          │
│                              ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                      Cloud SQL                               │  │
│  │                   (PostgreSQL 15)                           │  │
│  │                   + TimescaleDB                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Cloud Storage  │
                    │  (documents)    │
                    └─────────────────┘
```

---

## Terraform Configuration

### Main Configuration

```hcl
# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "nifty50-rag-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-south1"  # Mumbai
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-south1-a"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}
```

### VPC Network

```hcl
# network.tf

resource "google_compute_network" "vpc" {
  name                    = "nifty50-rag-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "nifty50-rag-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = true
}

# Firewall rules
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # IAP range
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = ["10.0.0.0/24"]
}
```

### Compute Engine VM

```hcl
# compute.tf

resource "google_compute_address" "static_ip" {
  name   = "nifty50-rag-ip"
  region = var.region
}

resource "google_compute_instance" "app_server" {
  name         = "nifty50-rag-server"
  machine_type = "e2-standard-4"  # 4 vCPU, 16 GB RAM
  zone         = var.zone
  
  tags = ["web", "ssh"]
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100  # GB
      type  = "pd-ssd"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }
  
  metadata_startup_script = file("${path.module}/scripts/startup.sh")
  
  service_account {
    email  = google_service_account.app_sa.email
    scopes = ["cloud-platform"]
  }
  
  labels = {
    environment = var.environment
    app         = "nifty50-rag"
  }
}

# Service account
resource "google_service_account" "app_sa" {
  account_id   = "nifty50-rag-app"
  display_name = "NIFTY 50 RAG Application"
}

# IAM bindings
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### Cloud SQL

```hcl
# database.tf

resource "google_sql_database_instance" "postgres" {
  name             = "nifty50-rag-db"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier = "db-custom-2-8192"  # 2 vCPU, 8 GB RAM
    
    disk_size         = 50
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      
      backup_retention_settings {
        retained_backups = 7
      }
    }
    
    maintenance_window {
      day  = 7  # Sunday
      hour = 4  # 4 AM
    }
    
    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }
  
  deletion_protection = true
}

resource "google_sql_database" "app_db" {
  name     = "nifty50_rag"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app_user" {
  name     = "app"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = false
}
```

### Cloud Storage

```hcl
# storage.tf

resource "google_storage_bucket" "documents" {
  name          = "nifty50-rag-documents-${var.project_id}"
  location      = var.region
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "backups" {
  name          = "nifty50-rag-backups-${var.project_id}"
  location      = var.region
  force_destroy = false
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
```

### Secret Manager

```hcl
# secrets.tf

resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "groq_api_key" {
  secret_id = "groq-api-key"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "openai_api_key" {
  secret_id = "openai-api-key"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "llama_cloud_api_key" {
  secret_id = "llama-cloud-api-key"
  
  replication {
    auto {}
  }
}
```

---

## Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  # FastAPI Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@${DB_HOST}:5432/nifty50_rag
      - REDIS_URL=redis://redis:6379/0
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
      - GROQ_API_KEY=${GROQ_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LLAMA_CLOUD_API_KEY=${LLAMA_CLOUD_API_KEY}
      - GCS_BUCKET=${GCS_BUCKET}
      - LANGCHAIN_TRACING_V2=true
      - LANGCHAIN_API_KEY=${LANGSMITH_API_KEY}
      - LANGCHAIN_PROJECT=nifty50-rag
    depends_on:
      - redis
      - qdrant
    volumes:
      - ./data:/app/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Next.js Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000/api/v1
    depends_on:
      - backend
    restart: unless-stopped

  # Qdrant Vector Database
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      - QDRANT__SERVICE__GRPC_PORT=6334
    restart: unless-stopped

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    restart: unless-stopped

  # Celery Worker
  celery_worker:
    build:
      context: ./backend
      dockerfile: Dockerfile
    command: celery -A app.workers.celery_app worker --loglevel=info --concurrency=4
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@${DB_HOST}:5432/nifty50_rag
      - REDIS_URL=redis://redis:6379/0
      - QDRANT_HOST=qdrant
      - GROQ_API_KEY=${GROQ_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LLAMA_CLOUD_API_KEY=${LLAMA_CLOUD_API_KEY}
      - GCS_BUCKET=${GCS_BUCKET}
    depends_on:
      - redis
      - backend
    restart: unless-stopped

  # Celery Beat (Scheduler)
  celery_beat:
    build:
      context: ./backend
      dockerfile: Dockerfile
    command: celery -A app.workers.celery_app beat --loglevel=info
    environment:
      - DATABASE_URL=postgresql://app:${DB_PASSWORD}@${DB_HOST}:5432/nifty50_rag
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - redis
      - celery_worker
    restart: unless-stopped

  # Nginx (Reverse Proxy)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/certbot:/var/www/certbot:ro
    depends_on:
      - backend
      - frontend
    restart: unless-stopped

volumes:
  qdrant_data:
  redis_data:
```

---

## Dockerfiles

### Backend Dockerfile

```dockerfile
# backend/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Frontend Dockerfile

```dockerfile
# frontend/Dockerfile

FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Production image
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
```

---

## Nginx Configuration

```nginx
# nginx/nginx.conf

events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8000;
    }

    upstream frontend {
        server frontend:3000;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;

    server {
        listen 80;
        server_name nifty50rag.com www.nifty50rag.com;
        
        # Redirect to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name nifty50rag.com www.nifty50rag.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
        ssl_prefer_server_ciphers off;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # API routes
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # SSE support
            proxy_set_header Connection '';
            proxy_buffering off;
            proxy_cache off;
            proxy_read_timeout 86400s;
        }

        # Frontend routes
        location / {
            limit_req zone=general burst=50 nodelay;
            
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

---

## Startup Script

```bash
#!/bin/bash
# scripts/startup.sh

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init --skip-diagnostics

# Clone repository
git clone https://github.com/your-org/nifty50-rag.git /opt/nifty50-rag
cd /opt/nifty50-rag

# Fetch secrets
export DB_PASSWORD=$(gcloud secrets versions access latest --secret="db-password")
export GROQ_API_KEY=$(gcloud secrets versions access latest --secret="groq-api-key")
export OPENAI_API_KEY=$(gcloud secrets versions access latest --secret="openai-api-key")
export LLAMA_CLOUD_API_KEY=$(gcloud secrets versions access latest --secret="llama-cloud-api-key")

# Start services
docker-compose up -d

# Setup log rotation
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    missingok
    delaycompress
    copytruncate
}
EOF

echo "Startup complete!"
```

---

## CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml

name: Deploy to GCP

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GCE_INSTANCE: nifty50-rag-server
  GCE_ZONE: asia-south1-a

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install pytest pytest-asyncio
      
      - name: Run tests
        run: |
          cd backend
          pytest tests/ -v

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to GCR
        uses: docker/login-action@v3
        with:
          registry: gcr.io
          username: _json_key
          password: ${{ secrets.GCP_SA_KEY }}
      
      - name: Build and push backend
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          push: true
          tags: gcr.io/${{ env.PROJECT_ID }}/nifty50-rag-backend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Build and push frontend
        uses: docker/build-push-action@v5
        with:
          context: ./frontend
          push: true
          tags: gcr.io/${{ env.PROJECT_ID }}/nifty50-rag-frontend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
      
      - name: Deploy to GCE
        run: |
          gcloud compute ssh ${{ env.GCE_INSTANCE }} --zone=${{ env.GCE_ZONE }} --command="
            cd /opt/nifty50-rag
            git pull origin main
            docker-compose pull
            docker-compose up -d --force-recreate
            docker system prune -f
          "
      
      - name: Health check
        run: |
          sleep 30
          curl -f https://nifty50rag.com/health || exit 1
```

---

## Environment Variables

```bash
# .env.example

# Database
DATABASE_URL=postgresql://app:password@localhost:5432/nifty50_rag
DB_HOST=localhost
DB_PASSWORD=your-db-password

# Redis
REDIS_URL=redis://localhost:6379/0

# Qdrant
QDRANT_HOST=localhost
QDRANT_PORT=6333

# LLM APIs
GROQ_API_KEY=gsk_xxx
OPENAI_API_KEY=sk-xxx
LLAMA_CLOUD_API_KEY=llx-xxx

# GCP
GCS_BUCKET=nifty50-rag-documents
GCP_PROJECT_ID=your-project-id

# Observability
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls__xxx
LANGCHAIN_PROJECT=nifty50-rag

# Security
JWT_SECRET_KEY=your-jwt-secret
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60

# Application
ENVIRONMENT=production
DEBUG=false
```

---

## Monitoring Setup

### Prometheus + Grafana (Optional)

```yaml
# docker-compose.monitoring.yml

version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

---

## Next Document

Continue to [09-EVALUATION.md](./09-EVALUATION.md) for evaluation and monitoring.

