# Create an AI Platform Notebooks instance 

resource "google_compute_instance" "caip_notebook" {
  name                      = var.name
  zone                      = var.zone
  machine_type              = var.machine_type
  allow_stopping_for_update = true
  
  network_interface {
      network = "default"
      access_config {
      }
  }

  scheduling {
      automatic_restart   = true
      on_host_maintenance = "TERMINATE"
  }

  service_account {
    scopes = [
        "cloud-platform"
    ]
  }

  metadata = {
      proxy_mode = "project_editors"
 #     container  = var.container_image
  }

  boot_disk {
      auto_delete  = true
      initialize_params {
          image = "deeplearning-platform-release/tf-1-15-cpu"
    }
  }
}