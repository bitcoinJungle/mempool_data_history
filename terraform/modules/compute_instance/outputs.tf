output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.bitcoin_jungle_node.name
}

output "instance_self_link" {
  description = "Self link of the compute instance"
  value       = google_compute_instance.bitcoin_jungle_node.self_link
}

output "instance_zone" {
  description = "Zone where the instance is running"
  value       = google_compute_instance.bitcoin_jungle_node.zone
}