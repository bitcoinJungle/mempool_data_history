variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-west1-a"
}

variable "bucket_name" {
  description = "Name of the storage bucket"
  type        = string
}

variable "bucket_location" {
  description = "Bucket location (e.g., US)"
  type        = string
  default     = "US"
}

variable "avro_file_dir" {
  description = "Local path to directory with Avro files"
  type        = string
  default     = "../samples/avrofiles"
}

variable "bq_dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "mempool_dataset"
}

variable "bq_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "US"
}

variable "vm_image" {
  description = "Boot disk image for VM"
  type        = string
  default     = "projects/debian-cloud/global/images/debian-12-bookworm-v20250610"
}

variable "subnetwork_id" {
  description = "Subnetwork ID for the VM"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account used by VM"
  type        = string
}

# # Option 1 : Send messages straight to Bigquery 
# variable "pubsub_topic_name" {
#   description = "The name of the Pub/Sub topic"
#   type        = string
#   default     = "mempool_topic"
# }

variable "scripts_bucket_name" {
  description = "GCS bucket name for startup scripts"
  type        = string
}

variable "hostname" {
  description = "hostname of the VM"
  type        = string
}
