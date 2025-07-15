resource "google_storage_bucket" "infra_scripts_bucket" {
  name          = var.scripts_bucket_name
  location      = var.bucket_location
  storage_class = "STANDARD"
  force_destroy = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    # Archive scripts after 1 day — they are only used at VM creation
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
    condition {
      age = 1
    }
  }
}

# # Option 1 : Send messages straight to Bigquery
# resource "google_storage_bucket_object" "mempool_watcher_script" {
#   name   = "scripts/mempool_watcher.py"
#   bucket = google_storage_bucket.infra_scripts_bucket.name
#   source = var.mempool_watcher_script_source
# }

resource "google_storage_bucket_object" "mempool_avro_watcher_script" {
  name   = "scripts/mempool_to_avrofiles_watcher.py"
  bucket = google_storage_bucket.infra_scripts_bucket.name
  source = var.mempool_to_avrofiles_watcher_script_source
}

resource "google_storage_bucket_iam_member" "vm_can_read_scripts" {
  bucket = google_storage_bucket.infra_scripts_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_storage_bucket" "auto_archive_bucket" {
  name                        = var.bucket_name
  location                    = var.bucket_location
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
    condition {
      age = 7
    }
  }
}

resource "google_storage_bucket_object" "avro_files" {
  for_each = fileset(var.avro_file_dir, "*.avro")

  name   = "source=bmon/dt=${regex("^.*?(\\d{4}-\\d{2}-\\d{2})T", each.key)[0]}/${each.key}"
  bucket = google_storage_bucket.auto_archive_bucket.name
  source = "${var.avro_file_dir}/${each.key}"
}
