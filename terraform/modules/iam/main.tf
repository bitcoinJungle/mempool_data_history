resource "google_project_iam_member" "scheduled_query_project" {
  for_each = toset(var.role_on_project)
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.service_account_email}"

  depends_on = [var.dataset_dependency, google_project_service.bigquery_data_transfer]
}

resource "google_project_service" "bigquery_data_transfer" {
  project = var.project_id
  service = "bigquerydatatransfer.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket_iam_member" "vm_can_write_avrofiles" {
  for_each = toset(var.roles_on_bucket)
  bucket   = var.bucket_name
  role     = each.value
  member   = "serviceAccount:${var.service_account_email}"
}