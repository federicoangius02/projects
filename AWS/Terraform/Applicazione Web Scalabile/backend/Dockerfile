FROM node:18-alpine

WORKDIR /app

# Copia i file delle dipendenze e installa
COPY package.json package-lock.json ./
RUN npm ci

# Copia il codice sorgente
COPY src ./src

# Esponi la porta 3000
EXPOSE 3000

# Avvia l'applicazione
CMD ["npm", "start"]