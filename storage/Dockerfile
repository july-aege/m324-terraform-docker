# Node.js 24 (LTS) auf Alpine: kleines Image, node:sqlite ist eingebaut
FROM node:24-alpine

WORKDIR /app

# Zuerst nur die Paketdateien kopieren und installieren.
# So muss Docker npm ci nur neu machen, wenn sich die Pakete ändern.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Danach den restlichen Code kopieren
COPY . .

# Ordner für die SQLite-Datei (hier wird das Docker-Volume eingehängt)
RUN mkdir -p /data

EXPOSE 3001

CMD ["node", "index.js"]
