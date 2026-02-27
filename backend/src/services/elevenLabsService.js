// src/services/elevenLabsService.js
// ElevenLabs Multilingual v2 TTS with phonetic code-switching

const axios = require('axios');

/**
 * Synthesize speech using ElevenLabs Multilingual v2.
 * Configured for code-switching between English technical terms and
 * regional agricultural vernacular (Tamil/Malayalam).
 * 
 * @param {string} text - Text to synthesize
 * @param {string} language - 'en', 'ta', or 'ml'
 * @returns {{ audio_base64: string, latency_ms: number }}
 */
async function synthesizeSpeech(text, language = 'en') {
    const startTime = Date.now();

    // Pick the correct voice for each language
    const voiceId = _getVoiceId(language);
    const modelId = process.env.ELEVENLABS_MODEL_ID || 'eleven_multilingual_v2';

    try {
        const response = await axios.post(
            `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
            {
                text: text,
                model_id: modelId,
                voice_settings: {
                    stability: 0.5,
                    similarity_boost: 0.75,
                    style: 0.3,
                    use_speaker_boost: true,
                },
                // Language hints for code-switching
                language_code: _getElevenLabsLang(language),
            },
            {
                headers: {
                    'Accept': 'audio/mpeg',
                    'Content-Type': 'application/json',
                    'xi-api-key': process.env.ELEVENLABS_API_KEY,
                },
                responseType: 'arraybuffer',
                timeout: 15000,
            }
        );

        const latencyMs = Date.now() - startTime;
        const audioBase64 = Buffer.from(response.data).toString('base64');

        return {
            audio_base64: audioBase64,
            content_type: 'audio/mpeg',
            latency_ms: latencyMs,
        };
    } catch (error) {
        console.error('ElevenLabs TTS error:', error.message);
        return {
            audio_base64: null,
            content_type: null,
            latency_ms: Date.now() - startTime,
            error: error.message,
        };
    }
}

/**
 * Get the correct ElevenLabs voice ID for the given language.
 */
function _getVoiceId(language) {
    switch (language) {
        case 'ta':
            return process.env.ELEVENLABS_TAMIL_VOICE_ID || 'pNInz6obpgDQGcFmaJgB';
        case 'ml':
            return process.env.ELEVENLABS_MALAYALAM_VOICE_ID || 'Lcf7135Sc6Sjn9as9vmb';
        case 'en':
        default:
            return process.env.ELEVENLABS_ENGLISH_VOICE_ID || 'pNInz6obpgDQGcFmaJgB';
    }
}

/**
 * Map language codes to ElevenLabs language identifiers.
 */
function _getElevenLabsLang(code) {
    const map = {
        'en': 'en',
        'ta': 'ta',
        'ml': 'ml',
    };
    return map[code] || 'en';
}

module.exports = { synthesizeSpeech };
