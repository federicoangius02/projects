const express = require('express');
const fileController = require('../controllers/file');
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

const router = express.Router();

router.post('/upload', upload.single('file'), fileController.uploadFile);
router.get('/files', fileController.listFiles);
router.get('/health', (req, res) => res.status(200).json({ status: 'OK' }));

module.exports = router;