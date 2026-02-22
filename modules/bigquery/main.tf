###############################################################################
# Module: BigQuery — Datasets + Tables for Medallion Architecture
# Bronze (raw), Silver (views), Gold (star schema), Staging, Data Quality
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

variable "labels" {
  type    = map(string)
  default = {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# DATASETS
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_bigquery_dataset" "bronze" {
  dataset_id    = "retail_bronze"
  project       = var.project_id
  location      = var.region
  friendly_name = "Bronze Layer — Raw Data"
  description   = "Raw, immutable data as received from source systems. No transformations applied."
  labels        = merge(var.labels, { layer = "bronze" })
}

resource "google_bigquery_dataset" "silver" {
  dataset_id    = "retail_silver"
  project       = var.project_id
  location      = var.region
  friendly_name = "Silver Layer — Cleansed Data"
  description   = "Deduplicated, type-cast, and standardized views over bronze tables."
  labels        = merge(var.labels, { layer = "silver" })
}

resource "google_bigquery_dataset" "gold" {
  dataset_id    = "retail_gold"
  project       = var.project_id
  location      = var.region
  friendly_name = "Gold Layer — Star Schema"
  description   = "Business-ready star schema: fact and dimension tables for analytics."
  labels        = merge(var.labels, { layer = "gold" })
}

resource "google_bigquery_dataset" "staging" {
  dataset_id                 = "retail_staging"
  project                    = var.project_id
  location                   = var.region
  friendly_name              = "Staging — Temporary Tables"
  description                = "Temporary workspace for ETL. Tables auto-expire after 24 hours."
  default_table_expiration_ms = 86400000
  labels                     = merge(var.labels, { layer = "staging" })
}

resource "google_bigquery_dataset" "data_quality" {
  dataset_id    = "retail_data_quality"
  project       = var.project_id
  location      = var.region
  friendly_name = "Data Quality — Test Results"
  description   = "Stores data quality test results and audit logs."
  labels        = merge(var.labels, { layer = "quality" })
}

# ═══════════════════════════════════════════════════════════════════════════════
# BRONZE TABLES
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_bigquery_table" "raw_transactions" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_transactions"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "bronze", source = "pos" })

  time_partitioning {
    type  = "DAY"
    field = "transaction_date"
  }

  clustering = ["store_id", "customer_id"]

  schema = jsonencode([
    { name = "transaction_id",        type = "STRING",    mode = "REQUIRED",  description = "Unique transaction identifier" },
    { name = "transaction_date",      type = "DATE",      mode = "REQUIRED",  description = "Transaction date (partition key)" },
    { name = "transaction_timestamp", type = "TIMESTAMP", mode = "NULLABLE",  description = "Exact transaction timestamp" },
    { name = "store_id",              type = "STRING",    mode = "REQUIRED",  description = "Store identifier (cluster key)" },
    { name = "customer_id",           type = "STRING",    mode = "NULLABLE",  description = "Customer identifier (cluster key)" },
    { name = "product_id",            type = "STRING",    mode = "REQUIRED",  description = "Product SKU identifier" },
    { name = "quantity",              type = "INT64",     mode = "NULLABLE",  description = "Quantity purchased" },
    { name = "unit_price",            type = "NUMERIC",   mode = "NULLABLE",  description = "Price per unit" },
    { name = "discount_amount",       type = "NUMERIC",   mode = "NULLABLE",  description = "Discount applied" },
    { name = "tax_amount",            type = "NUMERIC",   mode = "NULLABLE",  description = "Tax amount" },
    { name = "total_amount",          type = "NUMERIC",   mode = "NULLABLE",  description = "Total transaction amount" },
    { name = "payment_method",        type = "STRING",    mode = "NULLABLE",  description = "Payment method used" },
    { name = "channel",               type = "STRING",    mode = "NULLABLE",  description = "Sales channel (in_store, online, mobile)" },
    { name = "currency_code",         type = "STRING",    mode = "NULLABLE",  description = "ISO currency code" },
    { name = "_ingested_at",          type = "TIMESTAMP", mode = "NULLABLE",  description = "Ingestion timestamp" },
    { name = "_source_system",        type = "STRING",    mode = "NULLABLE",  description = "Source system identifier" },
    { name = "_source_file",          type = "STRING",    mode = "NULLABLE",  description = "Source file path" }
  ])
}

resource "google_bigquery_table" "raw_customers" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_customers"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "bronze", source = "crm" })

  clustering = ["customer_id"]

  schema = jsonencode([
    { name = "customer_id",       type = "STRING",    mode = "REQUIRED",  description = "Unique customer identifier" },
    { name = "first_name",        type = "STRING",    mode = "NULLABLE",  description = "Customer first name (PII)" },
    { name = "last_name",         type = "STRING",    mode = "NULLABLE",  description = "Customer last name (PII)" },
    { name = "email",             type = "STRING",    mode = "NULLABLE",  description = "Email address (PII)" },
    { name = "phone",             type = "STRING",    mode = "NULLABLE",  description = "Phone number (PII)" },
    { name = "date_of_birth",     type = "DATE",      mode = "NULLABLE",  description = "Date of birth (PII)" },
    { name = "gender",            type = "STRING",    mode = "NULLABLE",  description = "Gender identity" },
    { name = "address_line1",     type = "STRING",    mode = "NULLABLE",  description = "Street address (PII)" },
    { name = "city",              type = "STRING",    mode = "NULLABLE",  description = "City" },
    { name = "state_province",    type = "STRING",    mode = "NULLABLE",  description = "State or province" },
    { name = "postal_code",       type = "STRING",    mode = "NULLABLE",  description = "Postal code" },
    { name = "country_code",      type = "STRING",    mode = "NULLABLE",  description = "ISO country code" },
    { name = "loyalty_tier",      type = "STRING",    mode = "NULLABLE",  description = "Loyalty program tier" },
    { name = "signup_date",       type = "DATE",      mode = "NULLABLE",  description = "Account creation date" },
    { name = "last_activity_date",type = "DATE",      mode = "NULLABLE",  description = "Most recent activity date" },
    { name = "is_active",         type = "BOOLEAN",   mode = "NULLABLE",  description = "Active account flag" },
    { name = "marketing_opt_in",  type = "BOOLEAN",   mode = "NULLABLE",  description = "Marketing consent flag" },
    { name = "_ingested_at",      type = "TIMESTAMP", mode = "NULLABLE",  description = "Ingestion timestamp" },
    { name = "_source_system",    type = "STRING",    mode = "NULLABLE",  description = "Source system identifier" }
  ])
}

resource "google_bigquery_table" "raw_products" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_products"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "bronze", source = "catalog" })

  clustering = ["category_l1", "brand"]

  schema = jsonencode([
    { name = "product_id",       type = "STRING",  mode = "REQUIRED",  description = "Unique product SKU" },
    { name = "product_name",     type = "STRING",  mode = "NULLABLE",  description = "Product display name" },
    { name = "category_l1",      type = "STRING",  mode = "NULLABLE",  description = "Top-level category" },
    { name = "category_l2",      type = "STRING",  mode = "NULLABLE",  description = "Mid-level category" },
    { name = "category_l3",      type = "STRING",  mode = "NULLABLE",  description = "Sub-category" },
    { name = "brand",            type = "STRING",  mode = "NULLABLE",  description = "Product brand" },
    { name = "supplier_id",      type = "STRING",  mode = "NULLABLE",  description = "Supplier identifier" },
    { name = "unit_cost",        type = "NUMERIC", mode = "NULLABLE",  description = "Cost per unit" },
    { name = "list_price",       type = "NUMERIC", mode = "NULLABLE",  description = "List price" },
    { name = "weight_kg",        type = "FLOAT64", mode = "NULLABLE",  description = "Product weight in kg" },
    { name = "is_active",        type = "BOOLEAN", mode = "NULLABLE",  description = "Active product flag" },
    { name = "launch_date",      type = "DATE",    mode = "NULLABLE",  description = "Product launch date" },
    { name = "discontinue_date", type = "DATE",    mode = "NULLABLE",  description = "Discontinuation date" },
    { name = "_ingested_at",     type = "TIMESTAMP", mode = "NULLABLE", description = "Ingestion timestamp" },
    { name = "_source_system",   type = "STRING",  mode = "NULLABLE",  description = "Source system identifier" }
  ])
}

resource "google_bigquery_table" "raw_stores" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_stores"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "bronze", source = "store-ops" })

  schema = jsonencode([
    { name = "store_id",        type = "STRING",    mode = "REQUIRED",  description = "Unique store identifier" },
    { name = "store_name",      type = "STRING",    mode = "NULLABLE",  description = "Store display name" },
    { name = "store_type",      type = "STRING",    mode = "NULLABLE",  description = "Store type (flagship, standard, outlet)" },
    { name = "address",         type = "STRING",    mode = "NULLABLE",  description = "Street address" },
    { name = "city",            type = "STRING",    mode = "NULLABLE",  description = "City" },
    { name = "state_province",  type = "STRING",    mode = "NULLABLE",  description = "State or province" },
    { name = "country_code",    type = "STRING",    mode = "NULLABLE",  description = "ISO country code" },
    { name = "region",          type = "STRING",    mode = "NULLABLE",  description = "Business region (AMERICAS, EMEA, APAC)" },
    { name = "timezone",        type = "STRING",    mode = "NULLABLE",  description = "Store timezone" },
    { name = "square_footage",  type = "INT64",     mode = "NULLABLE",  description = "Store size in sq ft" },
    { name = "open_date",       type = "DATE",      mode = "NULLABLE",  description = "Store opening date" },
    { name = "close_date",      type = "DATE",      mode = "NULLABLE",  description = "Store closing date" },
    { name = "is_active",       type = "BOOLEAN",   mode = "NULLABLE",  description = "Active store flag" },
    { name = "manager_name",    type = "STRING",    mode = "NULLABLE",  description = "Store manager name" },
    { name = "_ingested_at",    type = "TIMESTAMP", mode = "NULLABLE",  description = "Ingestion timestamp" },
    { name = "_source_system",  type = "STRING",    mode = "NULLABLE",  description = "Source system identifier" }
  ])
}

resource "google_bigquery_table" "raw_inventory" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_inventory"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "bronze", source = "inventory" })

  time_partitioning {
    type  = "DAY"
    field = "snapshot_date"
  }

  clustering = ["store_id", "product_id"]

  schema = jsonencode([
    { name = "snapshot_date",     type = "DATE",      mode = "REQUIRED",  description = "Inventory snapshot date (partition key)" },
    { name = "store_id",          type = "STRING",    mode = "REQUIRED",  description = "Store identifier (cluster key)" },
    { name = "product_id",        type = "STRING",    mode = "REQUIRED",  description = "Product identifier (cluster key)" },
    { name = "stock_on_hand",     type = "INT64",     mode = "NULLABLE",  description = "Current stock quantity" },
    { name = "stock_on_order",    type = "INT64",     mode = "NULLABLE",  description = "Quantity on order" },
    { name = "reorder_point",     type = "INT64",     mode = "NULLABLE",  description = "Reorder threshold" },
    { name = "last_received_date",type = "DATE",      mode = "NULLABLE",  description = "Last stock receipt date" },
    { name = "last_sold_date",    type = "DATE",      mode = "NULLABLE",  description = "Last sale date" },
    { name = "_ingested_at",      type = "TIMESTAMP", mode = "NULLABLE",  description = "Ingestion timestamp" },
    { name = "_source_system",    type = "STRING",    mode = "NULLABLE",  description = "Source system identifier" }
  ])
}

# ═══════════════════════════════════════════════════════════════════════════════
# DATA QUALITY TABLE
# ═══════════════════════════════════════════════════════════════════════════════

resource "google_bigquery_table" "test_results" {
  dataset_id = google_bigquery_dataset.data_quality.dataset_id
  table_id   = "test_results"
  project    = var.project_id
  labels     = merge(var.labels, { layer = "quality" })

  time_partitioning {
    type  = "DAY"
    field = "run_date"
  }

  schema = jsonencode([
    { name = "run_date",               type = "DATE",    mode = "REQUIRED",  description = "Test execution date" },
    { name = "test_name",              type = "STRING",  mode = "REQUIRED",  description = "Test identifier" },
    { name = "model_name",             type = "STRING",  mode = "NULLABLE",  description = "Table/model tested" },
    { name = "status",                 type = "STRING",  mode = "NULLABLE",  description = "Test result (pass/fail)" },
    { name = "failures",               type = "INT64",   mode = "NULLABLE",  description = "Number of failures" },
    { name = "rows_tested",            type = "INT64",   mode = "NULLABLE",  description = "Rows evaluated" },
    { name = "execution_time_seconds", type = "FLOAT64", mode = "NULLABLE",  description = "Test duration in seconds" },
    { name = "severity",               type = "STRING",  mode = "NULLABLE",  description = "Test severity (ERROR, WARN)" }
  ])
}

# ═══════════════════════════════════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════════════════════════════════

output "dataset_ids" {
  description = "Map of dataset IDs"
  value = {
    bronze       = google_bigquery_dataset.bronze.dataset_id
    silver       = google_bigquery_dataset.silver.dataset_id
    gold         = google_bigquery_dataset.gold.dataset_id
    staging      = google_bigquery_dataset.staging.dataset_id
    data_quality = google_bigquery_dataset.data_quality.dataset_id
  }
}

output "bronze_table_ids" {
  description = "Bronze table IDs"
  value = {
    transactions = google_bigquery_table.raw_transactions.table_id
    customers    = google_bigquery_table.raw_customers.table_id
    products     = google_bigquery_table.raw_products.table_id
    stores       = google_bigquery_table.raw_stores.table_id
    inventory    = google_bigquery_table.raw_inventory.table_id
  }
}
