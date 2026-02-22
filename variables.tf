###############################################################################
# Root Variables — Shared across all modules
###############################################################################

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "GCS bucket name for data lake"
  type        = string
}

variable "bronze_sources" {
  description = "List of bronze layer source folders"
  type        = list(string)
  default     = ["transactions", "customers", "products", "stores", "inventory"]
}

variable "pubsub_topics" {
  description = "Map of Pub/Sub topic configs"
  type = map(object({
    message_retention = string
  }))
  default = {
    "retail-transactions"    = { message_retention = "86400s" }
    "retail-inventory"       = { message_retention = "86400s" }
    "retail-dead-letter"     = { message_retention = "86400s" }
    "pipeline-notifications" = { message_retention = "86400s" }
  }
}

variable "labels" {
  description = "Common labels applied to all resources"
  type        = map(string)
  default     = {}
}
