###############################################################################
# Lab 02: Enterprise Analytics Platform — Terraform Root Module
# Orchestrates all infrastructure modules for the medallion architecture.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    project     = "enterprise-analytics"
  })
}

# ============================================================================
# Module: APIs — Enable required GCP services
# ============================================================================
module "apis" {
  source     = "./modules/apis"
  project_id = var.project_id
}

# ============================================================================
# Module: GCS — Data lake bucket with bronze folder structure
# ============================================================================
module "gcs" {
  source         = "./modules/gcs"
  project_id     = var.project_id
  region         = var.region
  bucket_name    = var.bucket_name
  bronze_sources = var.bronze_sources
  labels         = local.common_labels
  depends_on     = [module.apis]
}

# ============================================================================
# Module: BigQuery — Datasets + tables (bronze, silver, gold, staging, quality)
# ============================================================================
module "bigquery" {
  source      = "./modules/bigquery"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  labels      = local.common_labels
  depends_on  = [module.apis]
}

# ============================================================================
# Module: Pub/Sub — Topics + subscriptions for streaming infrastructure
# ============================================================================
module "pubsub" {
  source        = "./modules/pubsub"
  project_id    = var.project_id
  environment   = var.environment
  pubsub_topics = var.pubsub_topics
  labels        = local.common_labels
  depends_on    = [module.apis]
}

# ============================================================================
# Module: Monitoring — Dashboard + alerting policies
# ============================================================================
module "monitoring" {
  source      = "./modules/monitoring"
  project_id  = var.project_id
  environment = var.environment
  depends_on  = [module.bigquery, module.pubsub]
}

# ============================================================================
# Module: Data Catalog — Taxonomy + policy tags for PII classification
# ============================================================================
module "data_catalog" {
  source      = "./modules/data_catalog"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  depends_on  = [module.apis]
}
