###############################################################################
# Root Outputs — Key resource identifiers for reference
###############################################################################

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "bucket_name" {
  description = "Data lake bucket name"
  value       = module.gcs.bucket_name
}

output "bucket_url" {
  description = "Data lake bucket URL"
  value       = module.gcs.bucket_url
}

output "dataset_ids" {
  description = "BigQuery dataset IDs"
  value       = module.bigquery.dataset_ids
}

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value       = module.pubsub.topic_names
}

output "pubsub_subscriptions" {
  description = "Pub/Sub subscription names"
  value       = module.pubsub.subscription_names
}

output "monitoring_dashboard_id" {
  description = "Monitoring dashboard ID"
  value       = module.monitoring.dashboard_id
}

output "data_catalog_taxonomy_id" {
  description = "Data Catalog taxonomy ID"
  value       = module.data_catalog.taxonomy_id
}
