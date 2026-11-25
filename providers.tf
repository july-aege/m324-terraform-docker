# Welche Terraform-Version und welcher Provider gebraucht werden.
# Der Provider «kreuzwerker/docker» ist das Plugin, das mit Docker spricht.
terraform {
  required_version = ">= 1.5"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Verbindung zu Docker Desktop.
# Unter Windows läuft Docker über eine «named pipe» (npipe).
# Auf Mac/Linux: docker_host = "unix:///var/run/docker.sock"
provider "docker" {
  host = var.docker_host
}
