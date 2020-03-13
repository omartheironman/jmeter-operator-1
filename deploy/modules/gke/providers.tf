
provider "google" {
  project = var.project
  region  = var.region

  /* Set credentials either here or with
     export GOOGLE_APPLICATION_CREDENTIALS="/home/user/.gcloud/Terraform.json"
     Note that usage of GCS backend for state will only work with environment variable */
  #credentials = "${file("${var.credentials_file_path}")}"
}
