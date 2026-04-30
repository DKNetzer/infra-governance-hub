# 1. Create the Hub Dataplex Lake
resource "google_dataplex_lake" "governance_lake" {
  name         = "tpc-h-governance-lake"
  project      = var.hub_project_id
  location     = var.region
  display_name = "TPC-H Governance Lake"
}

# 2. Fetch Hub Project Info to get the Project Number
data "google_project" "hub" {
  project_id = var.hub_project_id
}

# 3. Local variable to construct the Service Agent Email
locals {
  dataplex_sa = "service-${data.google_project.hub.number}@gcp-sa-dataplex.iam.gserviceaccount.com"
}

# 4. IAM Handshake: Grant Hub SA access to the Spoke project
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

# 5. Create the Dataplex Zone inside the Governance Lake
resource "google_dataplex_zone" "governance_zone" {
  project      = var.hub_project_id
  location     = var.region
  lake         = google_dataplex_lake.governance_lake.name
  name         = "tpc-h-governance-zone"
  type         = "RAW" 
  
  discovery_spec {
    enabled = true
  }
  
  resource_spec {
    location_type = "SINGLE_REGION"
  }
}

# 6. Attach the Spoke BigQuery Dataset to the Zone
resource "google_dataplex_asset" "tpc_h_prod_asset" {
  project       = var.hub_project_id
  location      = var.region
  lake          = google_dataplex_lake.governance_lake.name
  dataplex_zone = google_dataplex_zone.governance_zone.name
  name          = "tpc-h-prod-asset"

  resource_spec {
    # This points across the project boundary to your physical data
    name = "projects/${var.spoke_project_id}/datasets/tpc_h_prod_iac"
    type = "BIGQUERY_DATASET" # <--- This is the exact fix
  }
  
  discovery_spec {
    enabled = true
  }
}