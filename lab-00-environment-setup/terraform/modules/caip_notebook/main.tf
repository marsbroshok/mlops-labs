# Create an AI Platform Notebooks instance 

resource "google_compute_instance" "caip_notebook" {
  name               = var.name
  zone               = var.zone
  machine_type       = var.machine_type
  
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "TERMINATE"
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      " https://www.googleapis.com/auth/userinfo.email"
    ]
  }

  metadata = {
    proxy_mode = "service_account",
    container = var.container_image
  }

}