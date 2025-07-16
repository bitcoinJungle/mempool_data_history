terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.42.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Storage buckets and scripts
module "buckets" {
  source                                     = "./modules/buckets"
  scripts_bucket_name                        = var.scripts_bucket_name
  bucket_name                                = var.bucket_name
  bucket_location                            = var.bucket_location  
  avro_file_dir                              = var.avro_file_dir
  service_account_email                      = var.service_account_email
  mempool_to_avrofiles_watcher_script_source = "${path.module}/../scripts/mempool_to_avrofiles_watcher.py"
  # # Option 1 : Send messages straight to Bigquery
  # mempool_watcher_script_source              = "${path.module}/../scripts/mempool_watcher.py"
}

# BigQuery resources
module "bigquery" {
  source                 = "./modules/bigquery"
  project_id             = var.project_id
  bq_dataset_id          = var.bq_dataset_id
  bq_location            = var.bq_location
  bucket_name            = module.buckets.auto_archive_bucket_name
  service_account_email  = var.service_account_email
  schema_file            = "${path.module}/../schemas/accepted_tx_schema.json"
  bloclevel_tx_schema    = "${path.module}/../schemas/bloclevel_tx_schema.json"
  iam_binding_dependency = module.iam_scheduled_query.scheduled_query_project_iam_binding
  depends_on = [
    module.buckets.avro_files_dependency
  ]
}

# # ----------------------------------------------
# # Option 1 : Send messages straight to Bigquery
# # ----------------------------------------------
# Pub/Sub resources
# module "pubsub" {
#   source                      = "./modules/pubsub" 
#   pubsub_topic_name           = var.pubsub_topic_name
#   bigquery_table_fullname     = "${var.project_id}.${module.bigquery.dataset_id}.${module.bigquery.accepted_tx_table_id}"
#   service_account_email       = var.service_account_email
#   project_id                  = var.project_id
#   depends_on = [
#     module.bigquery.accepted_tx_dependency
#   ]
# }

# Compute instance
module "compute_instance" {
  source                    = "./modules/compute_instance"
  vm_image                  = var.vm_image
  machine_type              = "n2d-standard-8"
  startup_script_tpl        = "${path.module}/../scripts/startup-script.sh.tpl"
  project_id                = var.project_id
  # # Option 1 : Send messages straight to Bigquery 
  # pubsub_topic_name       = module.pubsub.topic_name
  # startup-script-option1  = "${path.module}/../scripts/startup-script-option1.sh.tpl"
  infra_scripts_bucket_name = module.buckets.infra_scripts_bucket_name
  auto_archive_bucket_name  = module.buckets.auto_archive_bucket_name
  subnetwork_id             = var.subnetwork_id
  service_account_email     = var.service_account_email
  zone                      = var.zone
  hostname                  = var.hostname
  project_source            = "bitcoinJungle"
  scopes = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    # # Option 1 : Send messages straight to Bigquery 
    # "https://www.googleapis.com/auth/pubsub",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/devstorage.read_write"
  ]
  depends_on = [
    module.buckets.vm_can_read_scripts_dependency,
    module.buckets.mempool_avro_watcher_script_dependency,
    # # Option 1 : Send messages straight to Bigquery 
    # module.buckets.mempool_watcher_script_dependency,
    # module.pubsub.vm_can_publish_dependency,
  ]
}

module "iam_scheduled_query" {
  source                = "./modules/iam"
  project_id            = var.project_id
  service_account_email = var.service_account_email
  bq_dataset_id         = var.bq_dataset_id
  bucket_name           = module.buckets.auto_archive_bucket_name
  dataset_dependency    = module.bigquery.dataset_dependency
  role_on_project = [
    "roles/bigquery.admin"
  ]
  roles_on_bucket = [
  "roles/storage.objectAdmin"
]
}
