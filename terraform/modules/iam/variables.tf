variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account to assign IAM roles to."
  type        = string
}

variable "role_on_project" {
  description = "List of IAM roles to assign to the service account."
  type        = list(string)
}

variable "bq_dataset_id" {
  description = "The GCP dataset ID."
  type        = string
}

variable "dataset_dependency" {
  description = "The BigQuery dataset resource to depend on"
  type        = any
}

variable "roles_on_bucket" {
  type        = list(string)
  description = "IAM roles for the service account on the GCS bucket"
}

variable "bucket_name" {
  type        = string
  description = "Name of the GCS bucket where Avro files are stored"
}