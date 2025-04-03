// server.js
const express = require('express');
const app = express();
const port = 3001;  // Puoi scegliere una porta diversa

// Middleware per gestire le richieste JSON
app.use(express.json());

// Aggiungi qui eventuali route
app.get('/', (req, res) => {
    res.send('Hello from the backend!');
});

// Avvia il server
app.listen(port, () => {
    console.log(`Backend running at http://localhost:${port}`);
});
