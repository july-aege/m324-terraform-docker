# ---------------------------------------------------------------
# 1) Netzwerk und Volume
# ---------------------------------------------------------------

# Eigenes Netzwerk: Alle Container darin finden sich über ihren Namen,
# z. B. mqtt://mosquitto:1883 oder http://storage:3001
resource "docker_network" "weather" {
  name = "weather-net"
}

# Volume für die SQLite-Datenbank. Die Daten bleiben erhalten,
# auch wenn der storage-Container neu erstellt wird.
resource "docker_volume" "weather_data" {
  name = "weather-data"
}

# ---------------------------------------------------------------
# 2) Images
# ---------------------------------------------------------------

# Fertiges Image vom Docker Hub für den MQTT-Broker
resource "docker_image" "mosquitto" {
  name         = "eclipse-mosquitto:2"
  keep_locally = true
}

locals {
  # Ordner mit eigenem Dockerfile -> daraus wird je ein Image gebaut
  build_dirs = toset(["stations", "monitor", "storage", "dashboard"])

  # Gleiche Broker-Adresse für alle Node-Services
  broker_url = "mqtt://mosquitto:1883"
}

# Eigene Images aus den Dockerfiles bauen
resource "docker_image" "app" {
  for_each = local.build_dirs

  name = "m324-weather-${each.key}:latest"

  build {
    context = "${path.module}/${each.key}"
  }

  # Prüfsumme über alle Dateien im Ordner (ohne node_modules).
  # Ändert sich der Code, ändert sich die Prüfsumme -> Image wird neu gebaut.
  triggers = {
    code = sha1(join("", [
      for f in fileset("${path.module}/${each.key}", "**") :
      filesha1("${path.module}/${each.key}/${f}")
      if !startswith(f, "node_modules/")
    ]))
  }
}

# ---------------------------------------------------------------
# 3) Container
# ---------------------------------------------------------------

# MQTT-Broker
resource "docker_container" "mosquitto" {
  name  = "mosquitto"
  image = docker_image.mosquitto.image_id

  networks_advanced {
    name = docker_network.weather.id
  }

  ports {
    internal = 1883
    external = 1883
  }

  # Konfigurationsdatei beim Erstellen in den Container kopieren
  upload {
    file    = "/mosquitto/config/mosquitto.conf"
    content = file("${path.module}/mosquitto/mosquitto.conf")
  }
}

# Wetterstationen (ein Container pro Eintrag in var.stations)
resource "docker_container" "station" {
  for_each = var.stations

  name    = each.key
  image   = docker_image.app["stations"].image_id
  restart = "on-failure"

  env = [
    "STATION_ID=${each.value.id}",
    "INTERVAL=${each.value.interval}",
    # Python soll Ausgaben sofort zeigen (sonst sieht man keine Logs)
    "PYTHONUNBUFFERED=1",
  ]

  networks_advanced {
    name = docker_network.weather.id
  }

  depends_on = [docker_container.mosquitto]
}

# Monitor: prüft Messwerte und meldet ausgefallene Stationen
resource "docker_container" "monitor" {
  name  = "monitor"
  image = docker_image.app["monitor"].image_id

  env = [
    "BROKER_URL=${local.broker_url}",
    "STATIONS=${join(",", [for s in values(var.stations) : s.id])}",
  ]

  networks_advanced {
    name = docker_network.weather.id
  }

  depends_on = [docker_container.mosquitto]
}

# Storage: speichert Messwerte in SQLite, Abfrage-API auf Port 3001
resource "docker_container" "storage" {
  name  = "storage"
  image = docker_image.app["storage"].image_id

  env = [
    "BROKER_URL=${local.broker_url}",
    "DB_FILE=/data/weather.db",
    "PORT=3001",
  ]

  networks_advanced {
    name = docker_network.weather.id
  }

  ports {
    internal = 3001
    external = 3001
  }

  volumes {
    volume_name    = docker_volume.weather_data.name
    container_path = "/data"
  }

  depends_on = [docker_container.mosquitto]
}

# Dashboard: Webseite auf Port 3000
resource "docker_container" "dashboard" {
  name  = "dashboard"
  image = docker_image.app["dashboard"].image_id

  env = [
    "BROKER_URL=${local.broker_url}",
    "STORAGE_URL=http://storage:3001",
    "PORT=3000",
  ]

  networks_advanced {
    name = docker_network.weather.id
  }

  ports {
    internal = 3000
    external = 3000
  }

  depends_on = [docker_container.mosquitto, docker_container.storage]
}
