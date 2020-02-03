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

