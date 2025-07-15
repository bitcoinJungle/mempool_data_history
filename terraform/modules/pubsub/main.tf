# # ----------------------------------------------
# # Option 1 : Send messages straight to Bigquery
# # ----------------------------------------------

# resource "google_pubsub_topic" "mempool_data" {
#   name = var.pubsub_topic_name
# }

# resource "google_pubsub_subscription" "bitcoin_logs_to_bq" {
#   name  = "bitcoin-logs-to-bq"
#   topic = google_pubsub_topic.mempool_data.id

#   ack_deadline_seconds       = 10
#   message_retention_duration = "604800s"

#   expiration_policy {
#     ttl = "604800s"
#   }

#   bigquery_config {
#     table               = var.bigquery_table_fullname
#     drop_unknown_fields = true
#     write_metadata      = false
#     use_table_schema    = true
#   }
# }

# resource "google_pubsub_topic_iam_member" "vm_can_publish" {
#   topic  = google_pubsub_topic.mempool_data.name
#   role   = "roles/pubsub.publisher"
#   member = "serviceAccount:${var.service_account_email}"
# }

# data "google_project" "project" {}

# resource "google_project_iam_member" "pubsub_service_agent_bq_writer" {
#   project = var.project_id
#   role    = "roles/bigquery.dataEditor"
#   member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
# }