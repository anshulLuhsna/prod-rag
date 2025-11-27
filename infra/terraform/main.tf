# GCP VM for NIFTY 50 RAG MVP Development
# This creates a single VM where we'll develop and run the MVP

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  
  # Optional: Store state in GCS (uncomment when ready)
  # backend "gcs" {
  #   bucket = "nifty50-rag-terraform-state"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Get your external IP for firewall rule
data "http" "my_ip" {
  url = "https://api.ipify.org"
}

# SSH Key handling - use existing or generate new
locals {
  # Determine SSH key path
  # If user specified a path, use it
  # Otherwise, try to find common locations
  ssh_key_path = var.existing_ssh_public_key_path != "" ? var.existing_ssh_public_key_path : (
    # Try project .ssh directory first
    fileexists("${path.module}/../.ssh/id_rsa.pub") ? "${path.module}/../.ssh/id_rsa.pub" : ""
  )
  
  # Check if we should use existing key
  # Only if: use_existing_ssh_key is true AND key path is specified/exists
  should_use_existing = var.use_existing_ssh_key && (
    var.existing_ssh_public_key_path != "" ? fileexists(var.existing_ssh_public_key_path) : (
      local.ssh_key_path != "" && fileexists(local.ssh_key_path)
    )
  )
  
  # Final key path to use
  final_ssh_key_path = var.existing_ssh_public_key_path != "" ? var.existing_ssh_public_key_path : local.ssh_key_path
}

# SSH Key - either use existing or generate new
data "local_file" "existing_ssh_key" {
  count    = local.should_use_existing ? 1 : 0
  filename = local.final_ssh_key_path
}

resource "tls_private_key" "ssh_key" {
  count     = local.should_use_existing ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Determine which public key and private key path to use
locals {
  ssh_public_key = local.should_use_existing ? data.local_file.existing_ssh_key[0].content : tls_private_key.ssh_key[0].public_key_openssh
  ssh_private_key_path = local.should_use_existing ? replace(local.final_ssh_key_path, ".pub", "") : "${path.module}/../.ssh/nifty50_rag_key"
}

# Save SSH key locally (only if generating new)
resource "local_file" "private_key" {
  count           = local.should_use_existing ? 0 : 1
  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = local.ssh_private_key_path
  file_permission = "0600"
}

resource "local_file" "public_key" {
  count    = local.should_use_existing ? 0 : 1
  content  = tls_private_key.ssh_key[0].public_key_openssh
  filename = "${local.ssh_private_key_path}.pub"
}

# VPC Network (create if doesn't exist)
resource "google_compute_network" "vpc" {
  name                    = "nifty50-rag-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "nifty50-rag-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall rule for SSH (from any IP - for development)
# WARNING: This allows SSH from anywhere. For production, restrict to specific IPs.
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-nifty50-rag"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # Allow from any IP
  target_tags   = ["ssh-allowed"]
  
  description = "Allow SSH from any IP (development only - restrict for production)"
}

# Firewall rule for SSH via Identity-Aware Proxy (IAP)
# This allows connection via GCP Console SSH button
resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "allow-ssh-iap-nifty50-rag"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP IP range
  target_tags   = ["ssh-allowed"]
  
  description = "Allow SSH via Identity-Aware Proxy (for GCP Console)"
}

# Firewall rule for application ports (for local testing)
resource "google_compute_firewall" "allow_app_ports" {
  name    = "allow-app-ports-nifty50-rag"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "8000", "6333", "6379", "5432"]  # Frontend, Backend, Qdrant, Redis, PostgreSQL
  }

  source_ranges = ["${chomp(data.http.my_ip.response_body)}/32"]
  target_tags   = ["app-ports"]
  
  description = "Allow application ports from current IP"
}

# Static IP address
resource "google_compute_address" "static_ip" {
  name   = "${var.vm_name}-ip"
  region = var.region
}

# VM Instance
resource "google_compute_instance" "dev_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["ssh-allowed", "app-ports"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  # SSH key for the default user
  metadata = {
    ssh-keys = "${var.ssh_user}:${chomp(local.ssh_public_key)}"
  }

  # Startup script to install Docker and basic tools
  metadata_startup_script = file("${path.module}/startup.sh")

  labels = {
    environment = "development"
    project     = "nifty50-rag"
    purpose     = "mvp-development"
  }
}
