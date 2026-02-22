###############################################################################
# Module: APIs — Enable required GCP services
# These must be active before any other resource can be created.
###############################################################################

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

locals {
  required_apis = [
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "dataflow.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

output "enabled_apis" {
  description = "List of enabled API services"
  value       = [for api in google_project_service.apis : api.service]
}
