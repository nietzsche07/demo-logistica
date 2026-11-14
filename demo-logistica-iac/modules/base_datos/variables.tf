variable "ambiente" {
  type = string
}

variable "memoria_mb" {
  type        = number
  description = "Límite de memoria del contenedor en MB"
}

variable "puerto" {
  type = number
}

variable "db_password" {
  type      = string
  sensitive = true
}
