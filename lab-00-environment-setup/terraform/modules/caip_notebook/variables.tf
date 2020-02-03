variable "name" {
    description = "The name of the CAIP notebook instance"
    type        = string
}

variable "zone" {
    description = "The instance's zone"
    type        = string
}

variable "machine_type" {
    description = "The instance's machine type"
    default     = "n1-standard-4"
}

variable "container_image" {
    description = "The custom container image for the instance"
}

variable "base_vm_image" {
    description = "The base image for the VM hosting the CAIP instance"
    default = "https://www.googleapis.com/compute/v1/projects/deeplearning-platform-release/global/images/family/common-container"
}
