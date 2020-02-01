terraform {
  backend "gcs" {
    bucket  = "jkterraform"
    prefix  = "terraform/state/mlops-workshop/lab-02"
  }
}