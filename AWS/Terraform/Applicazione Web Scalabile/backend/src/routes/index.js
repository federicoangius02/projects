const express = require('express');
const healthController = require('../controllers/health');  // Importa il controller

const router = express.Router();

// Route per la radice (/)
router.get('/', (req, res) => {
  res.send('Benvenuto alla mia applicazione!');
});

// Health check route
router.get('/health', healthController.getHealth);  // Usa il controller per /health

module.exports = router;