# Outputs for NIFTY 50 RAG MVP Terraform

output "vm_external_ip" {
  description = "External IP address of the VM (use this to SSH)"
  value       = google_compute_address.static_ip.address
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.dev_vm.network_interface[0].network_ip
}

output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.dev_vm.name
}

output "vm_zone" {
  description = "Zone where the VM is located"
  value       = google_compute_instance.dev_vm.zone
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ${path.module}/../.ssh/nifty50_rag_key ${var.ssh_user}@${google_compute_address.static_ip.address}"
}

output "ssh_config_entry" {
  description = "Add this to your ~/.ssh/config file for easier access"
  value = <<-EOT
Host nifty50-rag-dev
    HostName ${google_compute_address.static_ip.address}
    User ${var.ssh_user}
    IdentityFile ${path.module}/../.ssh/nifty50_rag_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
  EOT
}

output "project_setup_commands" {
  description = "Commands to run after SSH'ing into the VM"
  value = <<-EOT
    # After SSH'ing in, run:
    cd ~/nifty50-rag
    git clone <your-repo-url> .  # If using git
    # Or copy your project files here
    
    # Start services
    docker-compose up -d
  EOT
}

