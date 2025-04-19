const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB();
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
    logger.error(`Missing required environment variable: ${envVar}. Please set it in the ECS task definition or .env file.`);
    process.exit(1);
  }
});

// Routes
app.use('/', require('./routes'));

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await s3.headBucket({ Bucket: process.env.S3_BUCKET_NAME }).promise();
    await dynamodb.describeTable({ TableName: process.env.DYNAMODB_TABLE_NAME }).promise();
    res.status(200).json({ status: 'OK' });
  } catch (error) {
    logger.error('Health check failed:', error.message);
    res.status(500).json({ status: 'ERROR', service: error.service || 'unknown', error: error.message });
  }
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