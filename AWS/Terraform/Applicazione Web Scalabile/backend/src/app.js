require('dotenv').config();  // Carica le variabili d'ambiente dal file .env

const express = require('express');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;  // Usa la porta definita in .env o 3000 come fallback

// Middleware per il parsing del JSON
app.use(express.json());

// Route
app.use('/', routes);

// Avvia il server con gestione degli errori
app.listen(PORT, () => {
  console.log(`Server in ascolto sulla porta ${PORT}`);
}).on('error', (err) => {
  console.error('Errore durante l\'avvio del server:', err);
});