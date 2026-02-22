###############################################################################
# Module: Data Catalog — Taxonomy + Policy Tags for PII Classification
# Enables column-level security and data governance.
###############################################################################

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

# ═══════════════════════════════════════════════════════════════════════════════
# TAXONOMY — PII Classification
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_data_catalog_taxonomy" "pii_taxonomy" {
  project      = var.project_id
  region       = var.region
  display_name = "${var.environment}-pii-classification"
  description  = "Taxonomy for classifying Personally Identifiable Information (PII) in the retail analytics platform."

  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
}

# ── High Sensitivity PII ─────────────────────────────────────────────────────

resource "google_data_catalog_policy_tag" "high_sensitivity" {
  taxonomy     = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name = "High Sensitivity PII"
  description  = "Data that can directly identify an individual: SSN, full name + DOB, financial account numbers."
}

resource "google_data_catalog_policy_tag" "email" {
  taxonomy          = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name      = "Email Address"
  description       = "Customer email addresses — direct PII identifier."
  parent_policy_tag = google_data_catalog_policy_tag.high_sensitivity.id
}

resource "google_data_catalog_policy_tag" "phone" {
  taxonomy          = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name      = "Phone Number"
  description       = "Customer phone numbers — direct PII identifier."
  parent_policy_tag = google_data_catalog_policy_tag.high_sensitivity.id
}

resource "google_data_catalog_policy_tag" "date_of_birth" {
  taxonomy          = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name      = "Date of Birth"
  description       = "Customer date of birth — direct PII identifier."
  parent_policy_tag = google_data_catalog_policy_tag.high_sensitivity.id
}

# ── Medium Sensitivity PII ────────────────────────────────────────────────────

resource "google_data_catalog_policy_tag" "medium_sensitivity" {
  taxonomy     = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name = "Medium Sensitivity PII"
  description  = "Data that could identify an individual when combined: name, address, postal code."
}

resource "google_data_catalog_policy_tag" "person_name" {
  taxonomy          = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name      = "Person Name"
  description       = "Customer first and last names."
  parent_policy_tag = google_data_catalog_policy_tag.medium_sensitivity.id
}

resource "google_data_catalog_policy_tag" "address" {
  taxonomy          = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name      = "Mailing Address"
  description       = "Customer street address and postal code."
  parent_policy_tag = google_data_catalog_policy_tag.medium_sensitivity.id
}

# ── Low Sensitivity ──────────────────────────────────────────────────────────

resource "google_data_catalog_policy_tag" "low_sensitivity" {
  taxonomy     = google_data_catalog_taxonomy.pii_taxonomy.id
  display_name = "Low Sensitivity"
  description  = "Non-identifying demographic or preference data: gender, loyalty tier, marketing opt-in."
}

# ═══════════════════════════════════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════════════════════════════════

output "taxonomy_id" {
  description = "Data Catalog taxonomy ID"
  value       = google_data_catalog_taxonomy.pii_taxonomy.id
}

output "policy_tag_ids" {
  description = "Map of policy tag display names to IDs"
  value = {
    high_sensitivity = google_data_catalog_policy_tag.high_sensitivity.id
    email            = google_data_catalog_policy_tag.email.id
    phone            = google_data_catalog_policy_tag.phone.id
    date_of_birth    = google_data_catalog_policy_tag.date_of_birth.id
    medium_sensitivity = google_data_catalog_policy_tag.medium_sensitivity.id
    person_name      = google_data_catalog_policy_tag.person_name.id
    address          = google_data_catalog_policy_tag.address.id
    low_sensitivity  = google_data_catalog_policy_tag.low_sensitivity.id
  }
}
