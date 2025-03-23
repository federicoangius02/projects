const express = require('express');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 80;

// Middleware per il parsing del JSON
app.use(express.json());

// Route
app.use('/', routes);

// Avvia il server
app.listen(PORT, () => {
  console.log(`Server in ascolto sulla porta ${PORT}`);
});