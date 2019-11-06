terraform {
  required_version = ">= 0.12"
}

# Provision MVP KFP infrastructure using a reusable module
# module "dev_infrastructure" {
#  source      = "github.com/jarokaz/terraform-gcp-kfp"
#  project_id  = var.project_id
#  region      = var.region
#  zone        = var.zone
#  name_prefix = var.name_prefix
#}

# Provision MVP KFP infrastructure using reusable Terraform modules from
# github/jarokaz/terraform-gcp-kfp
provider "google" {
    project   = var.project_id 
}

# Create the GKE service account 
module "gke_service_account" {
  source                       = "github.com/jarokaz/terraform-gcp-kfp/modules/service_account"
  service_account_id           = "${var.name_prefix}-gke-sa"
  service_account_display_name = "The GKE service account"
  service_account_roles        = var.gke_service_account_roles
}

# Create the KFP service account 
module "kfp_service_account" {
  source                       = "github.com/jarokaz/terraform-gcp-kfp/modules/service_account"
  service_account_id           = "${var.name_prefix}-kfp-sa"
  service_account_display_name = "The KFP service account"
  service_account_roles        = var.kfp_service_account_roles
}

# Create the VPC for the KFP cluster
module "kfp_gke_vpc" {
  source                 = "github.com/jarokaz/terraform-gcp-kfp/modules/vpc"
  region                 = var.region
  network_name           = "${var.name_prefix}-network"
  subnet_name            = "${var.name_prefix}-subnet"
}

# Create the KFP GKE cluster
module "kfp_gke_cluster" {
  source                 = "github.com/jarokaz/terraform-gcp-kfp/modules/gke"
  name                   = "${var.name_prefix}-kfp-cluster"
  location               = var.zone != "" ? var.zone : var.region
  description            = "KFP GKE cluster"
  sa_full_id             = module.gke_service_account.service_account.email
  network                = module.kfp_gke_vpc.network_name
  subnetwork             = module.kfp_gke_vpc.subnet_name
  node_count             = var.cluster_node_count
  node_type              = var.cluster_node_type
}

# Create the MySQL instance for ML Metadata
module "ml_metadata_mysql" {
  source  = "github.com/jarokaz/terraform-gcp-kfp//modules/mysql"
  region  = var.region
  name    = "${var.name_prefix}-ml-metadata"
}

# Add the root user with no password to Cloud SQL instance.
resource "google_sql_user" "root_user" {
  project  = var.project_id
  name     = var.sql_username
  password = var.sql_password
  instance = module.ml_metadata_mysql.mysql_instance.name
}

# Create Cloud Storage bucket for artifact storage
resource "google_storage_bucket" "artifact_store" {
  name = "${var.name_prefix}-artifact-store"
}

# Install KFP
resource "null_resource" "kfp_installer" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud container clusters get-credentials "${module.kfp_gke_cluster.name}" --zone "${var.zone}" --project "${var.project_id}"
      gcloud iam service-accounts keys create application_default_credentials.json --iam-account="${module.kfp_service_account.service_account.email}"
      kubectl create namespace "${var.namespace}"
      kubectl create secret -n "${var.namespace}" generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
      kubectl create secret -n "${var.namespace}" generic mysql-credential --from-literal=username="${var.sql_username}" --from-literal=password="${var.sql_password}"
      kubectl create configmap -n "${var.namespace}" gcp-configs --from-literal=connection_name="${var.project_id}:${var.region}:${module.ml_metadata_mysql.mysql_instance.name}" --from-literal=bucket_name="${google_storage_bucket.artifact_store.name}"
      kustomize build ../kustomize | kubectl apply -f -
    EOT
  }
}



