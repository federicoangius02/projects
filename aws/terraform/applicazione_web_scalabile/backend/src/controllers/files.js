const AWS = require('aws-sdk');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [new winston.transports.Console()]
});

AWS.config.update({ region: process.env.AWS_REGION });
const s3 = new AWS.S3();
const dynamodb = new AWS.DynamoDB.DocumentClient();

const uploadFile = async (req, res) => {
  try {
    const { filename, description } = req.body;
    const file = req.file;

    const s3Params = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: `uploads/${Date.now()}_${filename}`,
      Body: file.buffer,
      ContentType: file.mimetype
    };

    const s3Response = await s3.upload(s3Params).promise();
    
    await dynamodb.put({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Item: {
        id: s3Response.Key,
        filename,
        description,
        url: s3Response.Location,
        createdAt: new Date().toISOString(),
        size: file.size
      }
    }).promise();

    logger.info('File uploaded successfully', { fileId: s3Response.Key });
    res.status(201).json({ 
      success: true,
      fileUrl: s3Response.Location 
    });

  } catch (error) {
    logger.error('File upload failed', { error: error.message });
    res.status(500).json({ 
      success: false,
      error: 'File processing error'
    });
  }
};

const listFiles = async (req, res) => {
  try {
    const result = await dynamodb.scan({
      TableName: process.env.DYNAMODB_TABLE_NAME,
      Limit: 100
    }).promise();

    logger.debug('Retrieved files list', { count: result.Items.length });
    res.json(result.Items);

  } catch (error) {
    logger.error('Failed to retrieve files', { error: error.message });
    res.status(500).json({ error: 'Database error' });
  }
};

module.exports = { uploadFile, listFiles };