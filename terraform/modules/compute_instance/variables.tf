variable "vm_image" {
  description = "Image to use for the VM"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
}

variable "startup_script_tpl" {
  description = "Path to the startup script template"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

# # Option 1 : Send messages straight to Bigquery 
# variable "pubsub_topic_name" {
#   description = "Pub/Sub topic name passed to the startup script"
#   type        = string
# }

variable "infra_scripts_bucket_name" {
  description = "GCS bucket where the startup script reads from"
  type        = string
}

variable "auto_archive_bucket_name" {
  description = "GCS bucket where the startup script reads from"
  type        = string
}

variable "subnetwork_id" {
  description = "Subnetwork ID for the VM"
  type        = string
}

variable "service_account_email" {
  description = "Service account email to attach to the VM"
  type        = string
}

variable "scopes" {
  description = "OAuth2 scopes to assign to the service account"
  type        = list(string)
}

variable "zone" {
  description = "GCP zone for the instance"
  type        = string
}

variable "hostname" {
  description = "hostname of the instance"
  type        = string
}