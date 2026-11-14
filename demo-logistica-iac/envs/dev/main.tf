terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # En Windows, si hay error de conexión con Docker, quita el # de la línea siguiente:
   host = "npipe:////.//pipe//docker_engine"
}

variable "ambiente" { type = string }
variable "memoria_mb" { type = number }
variable "puerto" { type = number }
variable "db_password" {
  type      = string
  sensitive = true
}

module "base_datos" {
  source      = "../../modules/base_datos"
  ambiente    = var.ambiente
  memoria_mb  = var.memoria_mb
  puerto      = var.puerto
  db_password = var.db_password
}

output "contenedor" {
  value = module.base_datos.contenedor
}
