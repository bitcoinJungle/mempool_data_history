output "infra_scripts_bucket_name" {
  description = "Name of the infrastructure scripts bucket"
  value       = google_storage_bucket.infra_scripts_bucket.name
}

output "auto_archive_bucket_name" {
  description = "Name of the bucket used to auto-archive AVRO files"
  value       = google_storage_bucket.auto_archive_bucket.name
}

output "avro_files_dependency" {
  description = "Dependency for AVRO file uploads to GCS"
  value       = google_storage_bucket_object.avro_files
}

output "mempool_watcher_script_dependency" {
  description = "Dependency object for the mempool_watcher script"
  value       = google_storage_bucket_object.mempool_watcher_script
}

output "mempool_avro_watcher_script_dependency" {
  description = "Dependency object for the mempool_watcher script"
  value       = google_storage_bucket_object.mempool_watcher_script
}

output "vm_can_read_scripts_dependency" {
  description = "Dependency object for VM's storage access IAM binding"
  value       = google_storage_bucket_iam_member.vm_can_read_scripts
}
