# # ----------------------------------------------
# # Option 1 : Send messages straight to Bigquery
# # ----------------------------------------------

# variable "pubsub_topic_name" {
#   description = "Name of the Pub/Sub topic to create"
#   type        = string
# }

# variable "bigquery_table_fullname" {
#   description = "Fully qualified BigQuery table name (project.dataset.table)"
#   type        = string
# }

# variable "service_account_email" {
#   description = "Service account email for the VM publishing to Pub/Sub"
#   type        = string
# }

# variable "project_id" {
#   description = "GCP project ID"
#   type        = string
# }