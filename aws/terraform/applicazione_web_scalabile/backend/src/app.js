const express = require('express');
const cors = require('cors');
const winston = require('winston');

// Configurazione logger
const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

// Carica .env solo in sviluppo
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
  logger.info('Running in development mode');
}

const app = express();
app.use(cors({
  origin: process.env.FRONTEND_URL || '*'
}));
app.use(express.json());

// Verifica variabili d'ambiente critiche
const requiredEnvVars = ['S3_BUCKET_NAME', 'DYNAMODB_TABLE_NAME', 'AWS_REGION'];
requiredEnvVars.forEach(envVar => {
  if (!process.env[envVar]) {
    logger.error(`Missing required environment variable: ${envVar}`);
    process.exit(1);
  }
});

// Routes
app.use('/', require('./routes'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK',
    environment: process.env.NODE_ENV || 'development'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
  logger.debug('Configuration:', {
    bucket: process.env.S3_BUCKET_NAME,
    table: process.env.DYNAMODB_TABLE_NAME,
    region: process.env.AWS_REGION
  });
});