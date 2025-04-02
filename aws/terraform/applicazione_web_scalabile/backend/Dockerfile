FROM node:20-alpine

WORKDIR /app

# 1. Installa solo le dipendenze necessarie
COPY package.json package-lock.json ./
RUN npm ci --only=production

# 2. Copia il codice sorgente
COPY . .

# 3. Imposta la porta e avvia
EXPOSE 3000
CMD ["npm", "start"]