# Create the Hub Dataplex Lake
resource "google_dataplex_lake" "governance_lake" {
  name         = "tpc-h-governance-lake"
  project      = var.hub_project_id
  location     = var.region
  display_name = "TPC-H Governance Lake"
}

# Fetch Hub Project Info to get the Project Number
data "google_project" "hub" {
  project_id = var.hub_project_id
}

# Local variable to construct the Service Agent Email
locals {
  dataplex_sa = "service-${data.google_project.hub.number}@gcp-sa-dataplex.iam.gserviceaccount.com"
}

# IAM Handshake: Grant Hub SA access to the Spoke project
resource "google_project_iam_member" "spoke_metadata_viewer" {
  project = var.spoke_project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:${local.dataplex_sa}"
}

resource "google_project_iam_member" "spoke_data_viewer" {
  project = var.spoke_project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${local.dataplex_sa}"
}