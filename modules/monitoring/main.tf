variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

resource "google_monitoring_dashboard" "analytics_platform" {
  project        = var.project_id
  dashboard_json = <<-JSON
  {
    "displayName": "${upper(var.environment)} - Enterprise Analytics Platform",
    "mosaicLayout": {
      "columns": 12,
      "tiles": [
        {
          "width": 6,
          "height": 4,
          "widget": {
            "title": "Pub/Sub - Undelivered Messages",
            "xyChart": {
              "dataSets": [{
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
                  }
                }
              }]
            }
          }
        },
        {
          "xPos": 6,
          "width": 6,
          "height": 4,
          "widget": {
            "title": "Pub/Sub - Publish Rate",
            "xyChart": {
              "dataSets": [{
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"pubsub_topic\" AND metric.type=\"pubsub.googleapis.com/topic/send_message_operation_count\""
                  }
                }
              }]
            }
          }
        },
        {
          "yPos": 4,
          "width": 6,
          "height": 4,
          "widget": {
            "title": "GCS - Object Count",
            "xyChart": {
              "dataSets": [{
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/object_count\""
                  }
                }
              }]
            }
          }
        },
        {
          "xPos": 6,
          "yPos": 4,
          "width": 6,
          "height": 4,
          "widget": {
            "title": "GCS - Total Bytes",
            "xyChart": {
              "dataSets": [{
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  }
  JSON
}

resource "google_monitoring_alert_policy" "dead_letter_alert" {
  project      = var.project_id
  display_name = "${upper(var.environment)} - Dead Letter Queue Depth > 100"
  combiner     = "OR"

  conditions {
    display_name = "Dead letter messages exceed threshold"
    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${var.environment}-dead-letter-monitor\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      comparison      = "COMPARISON_GT"
      threshold_value = 100
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  alert_strategy {
    auto_close = "1800s"
  }
  enabled = true
}

resource "google_monitoring_alert_policy" "pubsub_age_alert" {
  project      = var.project_id
  display_name = "${upper(var.environment)} - Oldest Unacked Message > 1hr"
  combiner     = "OR"

  conditions {
    display_name = "Oldest unacked message exceeds 1 hour"
    condition_threshold {
      filter          = "resource.type=\"pubsub_subscription\" AND metric.type=\"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3600
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }
  alert_strategy {
    auto_close = "1800s"
  }
  enabled = true
}

output "dashboard_id" {
  value = google_monitoring_dashboard.analytics_platform.id
}

output "alert_policy_ids" {
  value = [
    google_monitoring_alert_policy.dead_letter_alert.name,
    google_monitoring_alert_policy.pubsub_age_alert.name,
  ]
}
