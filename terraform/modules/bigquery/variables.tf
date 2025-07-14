variable "bq_dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "bq_location" {
  description = "BigQuery dataset location"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket containing AVRO files"
  type        = string
}

variable "schema_file" {
  description = "Path to the BigQuery schema JSON file"
  type        = string
}

variable "bloclevel_tx_schema" {
  description = "Path to the BigQuery schema JSON file for blocLevel_tx table"
  type        = string
}


variable "project_id" {
  description = "Project ID for BigQuery resources"
  type        = string
}

variable "service_account_email" {
  description = "Service account email used for scheduled queries"
  type        = string
}

variable "iam_binding_dependency" {
  description = "Dependency on IAM binding for scheduled query service account"
  type        = any
}
