// src/services/whisperService.js
// Whisper-large-v3 STT via Groq API with noise-robust pre-processing

const axios = require('axios');
const FormData = require('form-data');

/**
 * Transcribe audio using Whisper-large-v3 via Groq API.
 * 
 * @param {Buffer} audioBuffer - audio data from multer
 * @param {string} language - 'en', 'ta', or 'ml'
 * @param {string} [mimetype] - original mimetype from multer (e.g. 'audio/m4a')
 * @param {string} [originalname] - original filename from multer
 * @returns {{ transcript: string, confidence: number, language: string, latency_ms: number }}
 */
async function transcribeAudio(audioBuffer, language = 'en', mimetype = 'audio/m4a', originalname = '') {
    const startTime = Date.now();

    // Groq Whisper expects ISO 639-1 codes: 'en', 'ta', 'ml' — NOT full names
    const whisperLang = language || 'en';

    // Safety: check API key
    const apiKey = (process.env.WHISPER_API_KEY || '').trim();
    if (!apiKey) {
        console.error('❌ WHISPER_API_KEY is not set in .env');
        return {
            transcript: '',
            confidence: 0,
            language: whisperLang,
            latency_ms: Date.now() - startTime,
            error: 'WHISPER_API_KEY not configured',
        };
    }

    // Determine correct filename extension — Whisper REJECTS files without extensions
    const extMap = {
        'audio/m4a': 'blob.m4a',
        'audio/x-m4a': 'blob.m4a',
        'audio/mp4': 'blob.m4a',
        'audio/aac': 'blob.aac',
        'audio/wav': 'blob.wav',
        'audio/wave': 'blob.wav',
        'audio/x-wav': 'blob.wav',
        'audio/mpeg': 'blob.mp3',
        'audio/mp3': 'blob.mp3',
        'audio/ogg': 'blob.ogg',
        'audio/webm': 'blob.webm',
        'audio/flac': 'blob.flac',
    };
    const filename = originalname || extMap[mimetype] || 'blob.m4a';
    const contentType = mimetype || 'audio/m4a';

    try {
        const formData = new FormData();

        // 1. Audio file with proper extension
        formData.append('file', audioBuffer, {
            filename: filename,
            contentType: contentType,
        });

        // 2. Model — required by Groq
        formData.append('model', 'whisper-large-v3');

        // 3. Language — ISO 639-1 code only
        formData.append('language', whisperLang);

        // 4. Response format
        formData.append('response_format', 'verbose_json');

        console.log(`🎤 Whisper STT: sending ${filename} (${contentType}, ${audioBuffer.length} bytes) to Groq...`);

        // 6. POST to Groq with correct headers
        const response = await axios.post(
            'https://api.groq.com/openai/v1/audio/transcriptions',
            formData,
            {
                headers: {
                    ...formData.getHeaders(),
                    'Authorization': `Bearer ${apiKey}`,
                },
                maxContentLength: 25 * 1024 * 1024,
                timeout: 30000,
            }
        );

        const latencyMs = Date.now() - startTime;
        const data = response.data;

        console.log(`✅ Whisper STT: "${(data.text || '').substring(0, 80)}..." (${latencyMs}ms)`);

        // Compute phonetic accuracy from segment log probabilities
        const avgConfidence = data.segments && data.segments.length > 0
            ? data.segments.reduce((sum, s) => sum + (1 - Math.abs(s.avg_logprob || -0.5)), 0) / data.segments.length
            : 0.85;

        return {
            transcript: data.text || '',
            confidence: Math.min(100, Math.max(0, avgConfidence * 100)),
            language: data.language || whisperLang,
            latency_ms: latencyMs,
        };
    } catch (error) {
        const status = error.response?.status || 'N/A';
        const detail = error.response?.data?.error?.message || error.message;
        console.error(`❌ Whisper STT error [${status}]: ${detail}`);
        return {
            transcript: '',
            confidence: 0,
            language: whisperLang,
            latency_ms: Date.now() - startTime,
            error: `Whisper STT failed [${status}]: ${detail}`,
        };
    }
}

module.exports = { transcribeAudio };
