# Variables for NIFTY 50 RAG MVP Terraform

variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
  # Set this via terraform.tfvars or environment variable
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
  default     = "e2-standard-4"  # 4 vCPU, 16 GB RAM
  
  # Other options:
  # e2-standard-2  (2 vCPU, 8 GB)  - $50/month
  # e2-standard-4  (4 vCPU, 16 GB) - $100/month
  # e2-standard-8  (8 vCPU, 32 GB) - $200/month
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-ssd"  # SSD for better performance
  
  # Options:
  # pd-standard - Standard persistent disk
  # pd-ssd      - SSD persistent disk (faster, more expensive)
}

variable "ssh_user" {
  description = "SSH username for VM access"
  type        = string
  default     = "dev"
}

