resource "google_compute_instance" "bitcoin_jungle_node" {
  name         = "bitcoin-jungle-node"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    auto_delete = true
    device_name = "bitcoin-jungle-node"
    initialize_params {
      image = var.vm_image
      size  = 250
      type  = "pd-ssd"
    }
    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  metadata = {
    enable-osconfig           = "TRUE"
    startup-script            = templatefile(var.startup_script_tpl, {
      PROJECT_ID              = var.project_id,
      # # Option 1 : Send messages straight to Bigquery 
      # TOPIC_ID                = var.pubsub_topic_name,
      BUCKET_NAME             = var.infra_scripts_bucket_name
      BUCKET_NAME_DESTINATION = var.auto_archive_bucket_name
      HOSTNAME                = var.hostname
    })
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }
    subnetwork = var.subnetwork_id
    stack_type = "IPV4_ONLY"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = var.service_account_email
    scopes = var.scopes
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}
