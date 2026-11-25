# M324 – Terraform für Docker

Das ist mein MQTT-Wetterstationsprojekt aus M321. Drei Wetterstationen schicken Messwerte an einen MQTT-Broker. Ein Monitor prüft die Werte, ein Storage speichert sie in einer SQLite-Datenbank und ein Dashboard zeigt alles im Browser an.

Früher habe ich das Projekt mit Docker Compose gestartet und einen Teil von Hand. Jetzt startet Terraform alles. Jeder Service läuft in einem eigenen Container.

## Was man braucht

- Docker Desktop (muss laufen)
- Terraform

Die Ports 1883, 3000 und 3001 müssen frei sein.

## Starten

Alle Befehle mache ich in diesem Ordner, also dort, wo `main.tf` liegt.

```
terraform init
terraform plan
terraform apply
```

Bei `terraform apply` tippe ich `yes` ein. Beim ersten Mal dauert es ein bisschen, weil die Images gebaut werden.

## Dashboard öffnen

In Docker Desktop unter **Containers** klicke ich beim Container `dashboard` auf **3000:3000**. Man kann auch direkt http://localhost:3000 im Browser öffnen. Nach ein paar Sekunden sieht man die Messwerte.

## Stoppen

```
terraform destroy
```

Auch hier tippe ich `yes` ein. Dann löscht Terraform alle Container, das Netzwerk und das Volume wieder.

## Hinweis für Mac oder Linux

Ich habe das Projekt unter Windows gemacht. Auf Mac oder Linux muss man den Docker-Anschluss mitgeben:

```
terraform apply -var="docker_host=unix:///var/run/docker.sock"
```
