variable "scripts_bucket_name" {
  description = "Name of the bucket for storing infra scripts"
  type        = string
}

variable "bucket_name" {
  description = "Name of the general-purpose bucket (for AVROs)"
  type        = string
}

variable "bucket_location" {
  description = "GCP location for the buckets"
  type        = string
}

variable "mempool_watcher_script_source" {
  description = "Local path to the mempool_watcher.py script"
  type        = string
}

variable "avro_file_dir" {
  description = "Path to the directory containing AVRO files"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account to grant bucket access"
  type        = string
}
