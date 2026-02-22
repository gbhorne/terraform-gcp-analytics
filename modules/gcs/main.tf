###############################################################################
# Module: GCS — Data lake bucket with bronze folder structure
# Creates the landing zone for raw CSV ingestion.
###############################################################################

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "bronze_sources" {
  type = list(string)
}

variable "labels" {
  type    = map(string)
  default = {}
}

# ── Bucket ───────────────────────────────────────────────────────────────────
resource "google_storage_bucket" "data_lake" {
  name                        = var.bucket_name
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
  labels                      = var.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 730
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# ── Bronze folder placeholders ───────────────────────────────────────────────
resource "google_storage_bucket_object" "bronze_folders" {
  for_each = toset(var.bronze_sources)

  name    = "bronze/${each.value}/.keep"
  bucket  = google_storage_bucket.data_lake.name
  content = "placeholder"
}

# ── Additional operational folders ───────────────────────────────────────────
resource "google_storage_bucket_object" "dead_letter_folder" {
  name    = "dead-letter/.keep"
  bucket  = google_storage_bucket.data_lake.name
  content = "placeholder"
}

resource "google_storage_bucket_object" "dataflow_temp_folder" {
  name    = "dataflow-temp/.keep"
  bucket  = google_storage_bucket.data_lake.name
  content = "placeholder"
}

# ── Outputs ──────────────────────────────────────────────────────────────────
output "bucket_name" {
  description = "Data lake bucket name"
  value       = google_storage_bucket.data_lake.name
}

output "bucket_url" {
  description = "Data lake bucket URL"
  value       = google_storage_bucket.data_lake.url
}

output "bucket_self_link" {
  description = "Data lake bucket self link"
  value       = google_storage_bucket.data_lake.self_link
}
