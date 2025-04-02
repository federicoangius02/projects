const express = require('express');
const app = express();
const port = 3000;

// Una semplice route per testare la tua app
app.get('/', (req, res) => {
  res.send('Hello, Dockerized Node.js App!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`App running on port ${port}`);
});
