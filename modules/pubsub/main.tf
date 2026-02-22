###############################################################################
# Module: Pub/Sub — Topics + Subscriptions for streaming infrastructure
# Supports dead-letter routing and configurable message retention.
###############################################################################

variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "pubsub_topics" {
  type = map(object({
    message_retention = string
  }))
}

variable "labels" {
  type    = map(string)
  default = {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# TOPICS
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_pubsub_topic" "topics" {
  for_each = var.pubsub_topics

  name    = "${var.environment}-${each.key}"
  project = var.project_id
  labels  = merge(var.labels, { topic = each.key })

  message_retention_duration = each.value.message_retention
}

# ═══════════════════════════════════════════════════════════════════════════════
# SUBSCRIPTIONS
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_pubsub_subscription" "transactions_pull" {
  name    = "${var.environment}-transactions-pull"
  project = var.project_id
  topic   = google_pubsub_topic.topics["retail-transactions"].id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  expiration_policy {
    ttl = ""
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.topics["retail-dead-letter"].id
    max_delivery_attempts = 5
  }

  labels = merge(var.labels, { subscription = "transactions-pull" })
}

resource "google_pubsub_subscription" "inventory_pull" {
  name    = "${var.environment}-inventory-pull"
  project = var.project_id
  topic   = google_pubsub_topic.topics["retail-inventory"].id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  expiration_policy {
    ttl = ""
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.topics["retail-dead-letter"].id
    max_delivery_attempts = 5
  }

  labels = merge(var.labels, { subscription = "inventory-pull" })
}

resource "google_pubsub_subscription" "dead_letter_monitor" {
  name    = "${var.environment}-dead-letter-monitor"
  project = var.project_id
  topic   = google_pubsub_topic.topics["retail-dead-letter"].id

  ack_deadline_seconds       = 120
  message_retention_duration = "604800s"
  retain_acked_messages      = true

  expiration_policy {
    ttl = ""
  }

  labels = merge(var.labels, { subscription = "dead-letter-monitor" })
}

# ═══════════════════════════════════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════════════════════════════════

output "topic_names" {
  description = "Map of topic names"
  value       = { for k, v in google_pubsub_topic.topics : k => v.name }
}

output "topic_ids" {
  description = "Map of topic IDs"
  value       = { for k, v in google_pubsub_topic.topics : k => v.id }
}

output "subscription_names" {
  description = "List of subscription names"
  value = [
    google_pubsub_subscription.transactions_pull.name,
    google_pubsub_subscription.inventory_pull.name,
    google_pubsub_subscription.dead_letter_monitor.name,
  ]
}
