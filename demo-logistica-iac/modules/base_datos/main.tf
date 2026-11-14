terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

locals {
  nombre = "logistica-${var.ambiente}"
}

# Red propia del ambiente
resource "docker_network" "red" {
  name = "${local.nombre}-red"
}

# Volumen: los datos sobreviven aunque el contenedor se recree
resource "docker_volume" "datos" {
  name = "${local.nombre}-datos"
}

# Imagen de PostgreSQL (versión fija para reproducibilidad)
resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

# Base de datos del dominio de entregas (equivale al RDS en AWS)
resource "docker_container" "postgres" {
  name   = "${local.nombre}-postgres"
  image  = docker_image.postgres.image_id
  memory = var.memoria_mb

  env = [
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=entregas",
  ]

  ports {
    internal = 5432
    external = var.puerto
  }

  volumes {
    volume_name    = docker_volume.datos.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.red.name
  }

  labels {
    label = "ambiente"
    value = var.ambiente
  }
}
