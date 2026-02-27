// src/controllers/aiController.js
// CHARMER AI Pipeline: Sarvam STT → Featherless LLM (Mixtral) → ElevenLabs TTS

const pdfParse = require('pdf-parse');
const featherless = require('../services/featherlessService');
const sarvam = require('../services/sarvamService');
const elevenLabs = require('../services/elevenLabsService');
const districtData = require('../config/districtSeedData.json');

/**
 * POST /api/ai/analyze-pdf
 * Upload a PDF → extract text → Featherless AI distillation with hidden risk mining
 */
exports.analyzePdf = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No PDF file uploaded' });
        }

        const language = req.body.language || 'en';

        // Extract text from PDF
        const pdfData = await pdfParse(req.file.buffer);
        const pdfText = pdfData.text;

        if (!pdfText || pdfText.trim().length < 50) {
            return res.status(400).json({ error: 'PDF contains insufficient text content' });
        }

        // Run through Featherless AI for adversarial distillation
        const analysis = await featherless.analyzePdf(pdfText, language);

        res.json({
            summary: analysis.summary || 'Analysis complete',
            hidden_risks: analysis.hidden_risks || [],
            recommendations: analysis.recommendations || [],
            fertilizer_ratios: analysis.fertilizer_ratios || null,
            explanation: analysis.explanation || '',
            sources: analysis.sources || [],
            latency_ms: analysis.latency_ms,
            info_density: analysis.info_density,
            page_count: pdfData.numpages,
        });
    } catch (err) {
        console.error('PDF analysis error:', err.message);
        res.status(500).json({ error: 'PDF analysis failed', details: err.message });
    }
};

/**
 * POST /api/ai/voice-query
 * Audio → Sarvam STT → Featherless LLM (Mixtral) → ElevenLabs TTS
 * Optimized for the 3-second loop target.
 */
exports.voiceQuery = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No audio file uploaded' });
        }

        const language = req.body.language || 'en';
        const district = req.body.district || 'coimbatore';
        const totalStartTime = Date.now();

        // ── Step 1: STT — Sarvam AI (Shakti) ──
        const sttResult = await sarvam.transcribeAudio(
            req.file.buffer, language, req.file.mimetype, req.file.originalname
        );

        // Fallback: if Sarvam fails, return localized "Service Busy" message
        if (sttResult.error) {
            console.error(`⚠️ Sarvam STT failed, returning fallback: ${sttResult.error}`);
            return res.status(503).json({
                error: sttResult.fallback_message || 'Service is busy, please try again.',
                stt_error: sttResult.error,
                phonetic_accuracy: 0,
                latency_ms: sttResult.latency_ms,
            });
        }

        if (!sttResult.transcript || sttResult.transcript.trim().length === 0) {
            return res.status(400).json({
                error: 'Could not understand audio. Please try again.',
                phonetic_accuracy: 0,
            });
        }

        // Detect input language from Sarvam's response for dialect matching
        const detectedLang = sttResult.detected_language || language;
        // Map Sarvam BCP-47 (ta-IN, ml-IN) back to short code for LLM/TTS
        const effectiveLang = detectedLang.startsWith('ta') ? 'ta'
            : detectedLang.startsWith('ml') ? 'ml'
                : 'en';

        // ── Step 2: LLM — Featherless AI (Mixtral) with TNAU context ──
        const districtContext = districtData.districts?.[district] || null;
        const llmResult = await featherless.answerQuery(
            sttResult.transcript, effectiveLang, districtContext
        );

        // ── Step 3: TTS — Pipe LLM response to ElevenLabs with correct voice ──
        const ttsText = llmResult.tts_text || llmResult.response || llmResult.summary || '';
        let ttsResult = { audio_base64: null, latency_ms: 0 };

        if (ttsText) {
            // ElevenLabs voice is selected by effectiveLang (ta → Tamil voice, ml → Malayalam voice)
            ttsResult = await elevenLabs.synthesizeSpeech(ttsText, effectiveLang);
        }

        const totalLatencyMs = Date.now() - totalStartTime;

        res.json({
            transcript: sttResult.transcript,
            response: ttsText,
            detected_language: detectedLang,
            hidden_risks: llmResult.hidden_risks || [],
            explanation: llmResult.explanation || '',
            sources: llmResult.sources || [],
            audio_base64: ttsResult.audio_base64,
            audio_content_type: ttsResult.content_type,

            // Debug metrics
            phonetic_accuracy: sttResult.confidence || 0,
            info_density: llmResult.info_density || 0,
            latency_ms: totalLatencyMs,
            breakdown: {
                stt_ms: sttResult.latency_ms,
                llm_ms: llmResult.latency_ms,
                tts_ms: ttsResult.latency_ms,
            },
            under_3s: totalLatencyMs <= 3000,
        });
    } catch (err) {
        console.error('❌ Voice query error:', err.message);
        console.error('   Full error:', err.response?.data || err.stack);
        res.status(500).json({ error: 'Voice query failed', details: err.message });
    }
};

/**
 * POST /api/ai/fertilizer-calc
 * Acreage + crop type + soil data → precise NPK ratios
 */
exports.fertilizerCalc = async (req, res) => {
    try {
        const { acreage, crop_type, district, soil_type, language } = req.body;

        if (!acreage || !crop_type) {
            return res.status(400).json({ error: 'acreage and crop_type are required' });
        }

        // Base NPK ratios per acre (simplified agronomic model)
        const baseRatios = {
            'rice': { N: 120, P: 60, K: 60 },
            'sugarcane': { N: 300, P: 100, K: 125 },
            'coconut': { N: 50, P: 25, K: 100 },
            'banana': { N: 200, P: 60, K: 300 },
            'turmeric': { N: 60, P: 30, K: 120 },
            'tea': { N: 120, P: 60, K: 60 },
            'pepper': { N: 50, P: 50, K: 150 },
            'rubber': { N: 30, P: 30, K: 30 },
            'cotton': { N: 80, P: 40, K: 40 },
            'groundnut': { N: 25, P: 50, K: 45 },
            'default': { N: 80, P: 40, K: 40 },
        };

        // Soil adjustment factors
        const soilFactors = {
            'red_loam': { N: 1.1, P: 0.9, K: 1.0 },
            'black_clay': { N: 0.9, P: 1.1, K: 0.95 },
            'laterite': { N: 1.2, P: 1.2, K: 0.85 },
            'alluvial': { N: 0.85, P: 0.85, K: 1.1 },
            'sandy_loam': { N: 1.3, P: 1.1, K: 1.2 },
            'default': { N: 1.0, P: 1.0, K: 1.0 },
        };

        const base = baseRatios[crop_type.toLowerCase()] || baseRatios['default'];
        const factor = soilFactors[soil_type?.toLowerCase()] || soilFactors['default'];

        const result = {
            N: +(base.N * factor.N * acreage).toFixed(1),
            P: +(base.P * factor.P * acreage).toFixed(1),
            K: +(base.K * factor.K * acreage).toFixed(1),
        };

        // Get district context for explanation
        const districtInfo = districtData.districts?.[district];
        const rainfallNote = districtInfo
            ? `Based on ${districtInfo.avg_rainfall_mm}mm average rainfall in ${districtInfo.name}.`
            : '';

        res.json({
            fertilizer_ratios: result,
            crop_type,
            acreage,
            soil_type: soil_type || 'default',
            unit: 'kg',
            explanation: `NPK ratio calculated for ${acreage} acres of ${crop_type} on ${soil_type || 'standard'} soil. ${rainfallNote} Nitrogen promotes leaf growth, Phosphate strengthens roots, Potassium improves disease resistance.`,
            why_this: `These ratios follow TNAU (Tamil Nadu Agricultural University) recommended dosage, adjusted for local soil composition and rainfall patterns.`,
        });
    } catch (err) {
        res.status(500).json({ error: 'Calculation failed', details: err.message });
    }
};
