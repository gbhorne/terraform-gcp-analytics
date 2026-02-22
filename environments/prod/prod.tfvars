###############################################################################
# Prod Environment Configuration
# Update project_id and bucket_name for production project.
###############################################################################

project_id  = "REPLACE-WITH-PROD-PROJECT-ID"
bucket_name = "REPLACE-WITH-PROD-BUCKET"
region      = "us-central1"
environment = "prod"

labels = {
  team        = "data-engineering"
  cost_center = "analytics"
  environment = "prod"
}
