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

# # Option 1 : Send messages straight to Bigquery
# # Create the table that will be used by the pub/sub
# resource "google_bigquery_table" "accepted_tx" {
#   dataset_id          = google_bigquery_dataset.mempool_dataset.dataset_id
#   table_id            = "accepted_tx"
#   deletion_protection = false
#   schema              = file(var.schema_file)

#   # Partition the table by the DATE column "dt"
#   time_partitioning {
#     type  = "DAY"
#     field = "dt"

#     # (optional) require queries to filter on the partition column
#     # require_partition_filter = true
#   }
# }

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
  display_name           = "Get unique tx into blocLevel table"
  data_source_id         = "scheduled_query"
  destination_dataset_id = var.bq_dataset_id
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 02:00"

  # # Option 1 : Send messages straight to Bigquery
  # params = {
  #   query = templatefile("${path.module}/../../../queries/deduplicate_bloclevel_tx_option1.sql.tpl", {
  #     project_id         = var.project_id,
  #     dataset_id         = var.bq_dataset_id,
  #     bloclevel_table    = google_bigquery_table.bloclevel_tx.table_id
  #     avro_table         = google_bigquery_table.external_avro_table.table_id
  #     accepted_tx_table  = google_bigquery_table.accepted_tx.table_id
  #   })
  #
  # If not option 1 : 
  params = {
    query = templatefile("${path.module}/../../../queries/deduplicate_bloclevel_tx.sql.tpl", {
      project_id         = var.project_id,
      dataset_id         = var.bq_dataset_id,
      bloclevel_table    = google_bigquery_table.bloclevel_tx.table_id
      avro_table         = google_bigquery_table.external_avro_table.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}

resource "google_bigquery_data_transfer_config" "flag_replaced_tx" {
  display_name           = "Update replaced_by into bloclevel_tx table"
  data_source_id         = "scheduled_query"
  destination_dataset_id = var.bq_dataset_id
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 05:00"

  params = {
    query = templatefile("${path.module}/../../../queries/flag_replaced_transactions.sql.tpl", {
      project_id         = var.project_id,
      dataset_id         = var.bq_dataset_id,
      bloclevel_table    = google_bigquery_table.bloclevel_tx.table_id
      avro_table         = google_bigquery_table.external_avro_table.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}

resource "google_bigquery_data_transfer_config" "standard_bloclevel_update" {
  display_name           = "Update bloclevel_tx with blockchain data"
  data_source_id         = "scheduled_query"
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 07:00"

  params = {
    query = templatefile("${path.module}/../../../queries/standard_bloclevel_update.sql.tpl", {
      project_id      = var.project_id,
      dataset_id      = var.bq_dataset_id,
      bloclevel_table = google_bigquery_table.bloclevel_tx.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}

resource "google_bigquery_data_transfer_config" "extended_bloclevel_update" {
  display_name           = "Extended update bloclevel_tx with blockchain data"
  data_source_id         = "scheduled_query"
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 10:00"

  params = {
    query = templatefile("${path.module}/../../../queries/extended_bloclevel_update.sql.tpl", {
      project_id      = var.project_id,
      dataset_id      = var.bq_dataset_id,
      bloclevel_table = google_bigquery_table.bloclevel_tx.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}

resource "google_bigquery_data_transfer_config" "longtail_bloclevel_update" {
  display_name           = "Longtailed update bloclevel_tx with blockchain data"
  data_source_id         = "scheduled_query"
  location               = var.bq_location
  project                = var.project_id
  schedule               = "every day 13:00"

  params = {
    query = templatefile("${path.module}/../../../queries/longtail_bloclevel_update.sql.tpl", {
      project_id      = var.project_id,
      dataset_id      = var.bq_dataset_id,
      bloclevel_table = google_bigquery_table.bloclevel_tx.table_id
    })
  }

  service_account_name = var.service_account_email
  depends_on = [var.iam_binding_dependency]
}