# Utilizza un'immagine Node.js ufficiale
FROM node:20-alpine 

# Imposta la directory di lavoro
WORKDIR /app

# Copia package.json e installa dipendenze
COPY package.json package-lock.json ./
RUN npm install

# Copia il resto del codice
COPY . .

# Build della app
RUN npm run build

# Espone la porta 3000
EXPOSE 3000

# Comando di avvio
CMD ["npm", "start"]
