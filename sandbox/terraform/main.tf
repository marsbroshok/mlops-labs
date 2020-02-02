terraform {
  required_version = ">= 0.12"
  required_providers {
    google = "~> 2.0"
  }
}

# Provision MVP KFP infrastructure using reusable Terraform modules from
# github/jarokaz/terraform-gcp-kfp

provider "google" {
    project   = "mlops-workshop"
}


# Create a CAIP Notebook instance
module "caip_notebook" {
  source          = "./modules/caip_notebook"
  name            = "caip-notebook-01"
  zone            = "us-central1-a"
  machine_type    = "n1-standard-4"
  container_image = "gcr.io/mlops-workshop/mlops-dev:TF115-TFX015-KFP136"
}

