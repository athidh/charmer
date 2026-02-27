const express = require('express');
const multer = require('multer');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { protect: authMiddleware } = require('../middleware/authMiddleware');

// Multer — in-memory storage for file uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 25 * 1024 * 1024 }, // 25MB max
});

// Safe async handler — catches errors so server never crashes
const safe = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => {
        console.error(`❌ Route error: ${err.message}`);
        if (!res.headersSent) {
            res.status(500).json({
                error: 'Internal server error',
                details: err.message,
                hint: err.message.includes('API') || err.message.includes('key')
                    ? 'Check that all API keys are set in .env'
                    : undefined,
            });
        }
    });
};

// POST /api/ai/analyze-pdf — Upload + analyze PDF
router.post('/analyze-pdf', authMiddleware, upload.single('file'), safe(aiController.analyzePdf));

// POST /api/ai/voice-query — Audio → STT → LLM → TTS
router.post('/voice-query', authMiddleware, upload.single('audio'), safe(aiController.voiceQuery));

// POST /api/ai/fertilizer-calc — Calculate NPK ratios
router.post('/fertilizer-calc', authMiddleware, safe(aiController.fertilizerCalc));

module.exports = router;
