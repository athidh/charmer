// src/services/sarvamService.js
// Sarvam AI STT — model: saarathi, header: api-key

const axios = require('axios');
const FormData = require('form-data');

const SARVAM_STT_URL = 'https://api.sarvam.ai/speech-to-text';

// Localized "Service Busy" fallback messages
const SERVICE_BUSY = {
    'en': 'Service is busy, please try again in a moment.',
    'ta': 'சேவை பிசியாக உள்ளது, சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.',
    'ml': 'സേവനം തിരക്കിലാണ്, ദയവായി കുറച്ച് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
};

function _getSarvamLangCode(lang) {
    switch (lang) {
        case 'ta': return 'ta-IN';
        case 'ml': return 'ml-IN';
        case 'en':
        default: return 'en-IN';
    }
}

/**
 * Transcribe audio using Sarvam AI.
 */
async function transcribeAudio(audioBuffer, language = 'en', mimetype = 'audio/wav', originalname = '') {
    const startTime = Date.now();
    const langCode = _getSarvamLangCode(language);

    const apiKey = (process.env.SARVAM_API_KEY || '').trim();
    if (!apiKey || apiKey === 'your_sarvam_api_key_here') {
        console.error('❌ SARVAM_API_KEY is not set in .env');
        return {
            transcript: '',
            confidence: 0,
            language: language,
            detected_language: null,
            latency_ms: Date.now() - startTime,
            error: 'SARVAM_API_KEY not configured',
            fallback_message: SERVICE_BUSY[language] || SERVICE_BUSY['en'],
        };
    }

    // Filename with extension — APIs reject extensionless files
    const extMap = {
        'audio/m4a': 'recording.m4a', 'audio/x-m4a': 'recording.m4a',
        'audio/mp4': 'recording.m4a', 'audio/aac': 'recording.aac',
        'audio/wav': 'recording.wav', 'audio/wave': 'recording.wav',
        'audio/x-wav': 'recording.wav', 'audio/mpeg': 'recording.mp3',
        'audio/mp3': 'recording.mp3', 'audio/ogg': 'recording.ogg',
        'audio/webm': 'recording.webm', 'audio/flac': 'recording.flac',
    };
    const filename = originalname || extMap[mimetype] || 'recording.wav';
    const contentType = mimetype || 'audio/wav';

    try {
        const formData = new FormData();
        formData.append('file', audioBuffer, { filename, contentType });
        formData.append('language_code', langCode);
        formData.append('model', 'saaras:v3');
        formData.append('mode', 'transcribe');
        formData.append('with_timestamps', 'false');

        console.log(`🎤 Sarvam STT (saaras:v3): ${filename} (${contentType}, ${audioBuffer.length} bytes, lang=${langCode})`);

        const response = await axios.post(SARVAM_STT_URL, formData, {
            headers: {
                ...formData.getHeaders(),
                'api-subscription-key': apiKey,
            },
            maxContentLength: 25 * 1024 * 1024,
            timeout: 60000, // 60s — Saaras v3 needs more time for high-fidelity Indian language audio
        });

        const latencyMs = Date.now() - startTime;
        const data = response.data;
        const transcript = data.transcript || data.text || '';

        console.log(`✅ Sarvam STT [${langCode}]: "${transcript.substring(0, 80)}" (${latencyMs}ms)`);

        return {
            transcript,
            confidence: data.confidence ? data.confidence * 100 : 85,
            language,
            detected_language: data.language_code || langCode,
            latency_ms: latencyMs,
        };
    } catch (error) {
        const status = error.response?.status || 'N/A';
        const errData = error.response?.data;
        console.error(`❌ Sarvam STT [${status}]:`, JSON.stringify(errData, null, 2) || error.message);
        return {
            transcript: '',
            confidence: 0,
            language,
            detected_language: null,
            latency_ms: Date.now() - startTime,
            error: `Sarvam [${status}]: ${errData?.message || errData?.error || error.message}`,
            fallback_message: SERVICE_BUSY[language] || SERVICE_BUSY['en'],
        };
    }
}

module.exports = { transcribeAudio };
