output "dataset_id" {
  value       = google_bigquery_dataset.mempool_dataset.dataset_id
  description = "BigQuery dataset ID"
}

output "dataset_dependency" {
  value = google_bigquery_dataset.mempool_dataset
}

# # ----------------------------------------------
# # Option 1 : Send messages straight to Bigquery
# # ----------------------------------------------

# output "accepted_tx_table_id" {
#   value       = google_bigquery_table.accepted_tx.table_id
#   description = "Accepted transaction table ID"
# }

# output "accepted_tx_dependency" {
#   value = google_bigquery_table.accepted_tx
# }


