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

output "ssh_key_path" {
  description = "Path to SSH private key"
  value       = local.ssh_private_key_path
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i \"${local.ssh_private_key_path}\" ${var.ssh_user}@${google_compute_address.static_ip.address}"
}

output "ssh_config_entry" {
  description = "SSH config entry to add to ~/.ssh/config (or C:\\Users\\<user>\\.ssh\\config on Windows). Note: On Windows, change UserKnownHostsFile to NUL"
  value = <<-EOT
Host nifty50-rag-dev
    HostName ${google_compute_address.static_ip.address}
    User ${var.ssh_user}
    IdentityFile ${replace(local.ssh_private_key_path, "\\", "/")}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
  EOT
}

output "using_existing_key" {
  description = "Whether using existing SSH key or generated new one"
  value       = local.should_use_existing
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



