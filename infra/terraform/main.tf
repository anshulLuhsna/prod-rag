# GCP VM for NIFTY 50 RAG MVP Development
# This creates a single VM where we'll develop and run the MVP

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
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

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
  default     = "nifty50-rag-dev"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-standard-4"  # 4 vCPU, 16 GB RAM - good for MVP
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "dev"
}

# Get your external IP for firewall rule
data "http" "my_ip" {
  url = "https://api.ipify.org"
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

# Firewall rule for SSH (only from your IP)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-nifty50-rag"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${chomp(data.http.my_ip.response_body)}/32"]
  target_tags   = ["ssh-allowed"]
  
  description = "Allow SSH from current IP only"
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

# SSH Key (generate if not exists)
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save SSH key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/../.ssh/nifty50_rag_key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/../.ssh/nifty50_rag_key.pub"
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
    ssh-keys = "${var.ssh_user}:${tls_private_key.ssh_key.public_key_openssh}"
  }

  # Startup script to install Docker and basic tools
  metadata_startup_script = file("${path.module}/startup.sh")

  # Allow stopping the instance without deleting it
  allow_stop_for_update = true

  labels = {
    environment = "development"
    project     = "nifty50-rag"
    purpose     = "mvp-development"
  }
}

# Outputs
output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_address.static_ip.address
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.dev_vm.network_interface[0].network_ip
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ${path.module}/../.ssh/nifty50_rag_key ${var.ssh_user}@${google_compute_address.static_ip.address}"
}

output "ssh_config_entry" {
  description = "SSH config entry to add to ~/.ssh/config"
  value = <<-EOT
    Host nifty50-rag-dev
        HostName ${google_compute_address.static_ip.address}
        User ${var.ssh_user}
        IdentityFile ${path.module}/../.ssh/nifty50_rag_key
        StrictHostKeyChecking no
  EOT
}

