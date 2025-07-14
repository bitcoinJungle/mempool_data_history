resource "google_bigquery_dataset" "mempool_dataset" {
  dataset_id = var.bq_dataset_id
  location   = var.bq_location
}

resource "google_bigquery_table" "external_avro_table" {
  dataset_id         = google_bigquery_dataset.mempool_dataset.dataset_id
  table_id           = "mempool_accept_avrofiles_tx"
  deletion_protection = false

  external_data_configuration {
    source_uris            = ["gs://${var.bucket_name}/*"]
    source_format          = "AVRO"
    autodetect             = false
    ignore_unknown_values  = false

    hive_partitioning_options {
      mode                    = "AUTO"
      source_uri_prefix       = "gs://${var.bucket_name}"
      require_partition_filter = true
    }

    schema = file(var.schema_file)
  }
}

# Create the table that will be used by the pub/sub
resource "google_bigquery_table" "accepted_tx" {
  dataset_id          = google_bigquery_dataset.mempool_dataset.dataset_id
  table_id            = "accepted_tx"
  deletion_protection = false
  schema              = file(var.schema_file)

  # Partition the table by the DATE column "dt"
  time_partitioning {
    type  = "DAY"
    field = "dt"

    # (optional) require queries to filter on the partition column
    # require_partition_filter = true
  }
}

# Create the table that will be used to deduplicate tx and join them to the blockchain data
resource "google_bigquery_table" "bloclevel_tx" {
  dataset_id          = google_bigquery_dataset.mempool_dataset.dataset_id
  table_id            = "blocLevel_tx"
  deletion_protection = false
  schema              = file(var.bloclevel_tx_schema)

  time_partitioning {
    type  = "DAY"
    field = "last_seen_timestamp"
  }

  clustering = ["txid", "block_timestamp", "block_height"]
}

resource "google_bigquery_data_transfer_config" "deduplication_tx" {
  display_name           = "Get_unique_tx_into_final_table"
  data_source_id         = "scheduled_query"
  destination_dataset_id = var.bq_dataset_id
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 02:00"

  params = {
    query = templatefile("${path.module}/../../../queries/deduplicate_bloclevel_tx.sql.tpl", {
      project_id         = var.project_id,
      dataset_id         = var.bq_dataset_id,
      bloclevel_table    = google_bigquery_table.bloclevel_tx.table_id
      avro_table         = google_bigquery_table.external_avro_table.table_id
      accepted_tx_table  = google_bigquery_table.accepted_tx.table_id
    })
  }

  service_account_name = var.service_account_email

  depends_on = [var.iam_binding_dependency]
}

resource "google_bigquery_data_transfer_config" "update_bloclevel_tx" {
  display_name           = "Update bloclevel_tx with blockchain data"
  data_source_id         = "scheduled_query"
  destination_dataset_id = var.bq_dataset_id
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 04:00"

  params = {
    query = templatefile("${path.module}/../../../queries/update_bloclevel_tx.sql.tpl", {
      project_id      = var.project_id,
      dataset_id      = var.bq_dataset_id,
      bloclevel_table = google_bigquery_table.bloclevel_tx.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}
