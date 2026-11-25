# Adresse von Docker. Standard = Docker Desktop unter Windows.
variable "docker_host" {
  description = "Verbindung zur Docker Engine"
  type        = string
  default     = "npipe:////./pipe/docker_engine"
}

# Die Wetterstationen: Containername -> Stations-ID und Sendeintervall (Sekunden).
# Für jeden Eintrag erstellt Terraform einen eigenen Container.
variable "stations" {
  description = "Wetterstationen mit ID und Intervall in Sekunden"
  type = map(object({
    id       = string
    interval = number
  }))
  default = {
    station1 = { id = "WS-01", interval = 5 }
    station2 = { id = "WS-02", interval = 10 }
    station3 = { id = "WS-03", interval = 3 }
  }
}
