const express = require('express');
const healthController = require('../controllers/health');

const router = express.Router();

// Health check route
router.get('/health', healthController.getHealth);

module.exports = router;