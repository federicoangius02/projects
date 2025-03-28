# Dockerfile ottimizzato per struttura con /src
FROM node:20-alpine

# Imposta la directory di lavoro
WORKDIR /app

# 1. Prima copia SOLO i file delle dipendenze (per cache efficiente)
COPY package*.json ./

# 2. Installa le dipendenze (produzione)
RUN npm install --only=production

# 3. Copia SOLO la cartella src (evita file inutili)
COPY src ./src

# 4. Esponi la porta (documentativo, non apre realmente la porta)
EXPOSE 3000

# 5. Avvia l'app (usa la sintassi exec per migliori segnali di terminazione)
CMD ["npm", "start"]
