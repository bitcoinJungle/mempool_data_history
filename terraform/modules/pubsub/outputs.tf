output "topic_name" {
  description = "The name of the created Pub/Sub topic"
  value       = google_pubsub_topic.mempool_data.name
}

output "subscription_name" {
  description = "The name of the created Pub/Sub subscription"
  value       = google_pubsub_subscription.bitcoin_logs_to_bq.name
}

output "vm_can_publish_dependency" {
  description = "Dependency object for the VM's permission to publish to the Pub/Sub topic"
  value       = google_pubsub_topic_iam_member.vm_can_publish
}
