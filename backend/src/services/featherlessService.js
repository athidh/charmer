// src/services/featherlessService.js
// Featherless AI (Mixtral-8x7B) with RAG knowledge base injection
// Uses raw axios — NO OpenAI SDK (prevents 401 from mangled headers)

const axios = require('axios');
const fs = require('fs');
const path = require('path');

const FEATHERLESS_URL = 'https://api.featherless.ai/v1/chat/completions';

// ── RAG: Load knowledge base from file ──
let KNOWLEDGE_BASE = '';
try {
    KNOWLEDGE_BASE = fs.readFileSync(
        path.join(__dirname, '../config/knowledge.txt'), 'utf-8'
    );
    console.log(`📚 Knowledge base loaded: ${KNOWLEDGE_BASE.length} chars from knowledge.txt`);
} catch (err) {
    console.error('⚠️ Could not load knowledge.txt:', err.message);
    KNOWLEDGE_BASE = 'No knowledge base available.';
}

// ── System prompt with RAG injection ──
const SYSTEM_PROMPT = `You are CHARMER, an expert agrarian AI advisor for the Western Ghats corridor (Coimbatore/Kerala region).

You are an agrarian expert. Using this TNAU data as your primary knowledge source, answer the farmer's query in their local dialect.

=== YOUR KNOWLEDGE BASE (TNAU/KAU Certified) ===
${KNOWLEDGE_BASE}
=== END KNOWLEDGE BASE ===

RESPONSE RULES:
- Use ONLY the above knowledge base for factual data (fertilizer ratios, soil profiles, pest management)
- Lead with the MOST CRITICAL hidden risk
- Give SPECIFIC numbers (%, kg/acre, deviations) — cite from the knowledge base
- Always include "Why this?" for every recommendation
- Tag risks: LOW / MEDIUM / HIGH
- Use simple language a rural farmer can understand
- Response MUST be in the same local dialect used by the farmer
- Technical English terms (Nitrogen, Phosphate, pH) are OK but explain in context

Always return valid JSON with 'response', 'explanation', 'hidden_risks', and 'sources' fields.`;

/**
 * Raw axios call to Featherless AI with explicit Bearer auth.
 */
async function _callFeatherless(messages, maxTokens = 2048, temperature = 0.3) {
    const apiKey = (process.env.FEATHERLESS_API_KEY || '').trim();
    if (!apiKey) {
        throw new Error('FEATHERLESS_API_KEY is not set in .env');
    }

    const model = (process.env.FEATHERLESS_MODEL || 'mistralai/Mixtral-8x7B-Instruct-v0.1').trim();

    console.log(`🤖 Featherless: ${model} (${messages.length} msgs, max_tokens=${maxTokens})`);

    try {
        const response = await axios.post(
            FEATHERLESS_URL,
            {
                model,
                messages,
                temperature,
                max_tokens: maxTokens,
            },
            {
                headers: {
                    'Authorization': 'Bearer ' + apiKey,
                    'Content-Type': 'application/json',
                },
                timeout: 60000,
            }
        );

        const content = response.data.choices[0]?.message?.content || '';
        console.log(`✅ Featherless: ${content.length} chars`);
        return content;

    } catch (error) {
        console.error('❌ Featherless API error:');
        console.error('   Status:', error.response?.status);
        console.error('   Data:', JSON.stringify(error.response?.data, null, 2));
        throw new Error(`Featherless [${error.response?.status || 'N/A'}]: ${JSON.stringify(error.response?.data) || error.message}`);
    }
}

function _parseJson(text) {
    try {
        const jsonMatch = text.match(/```json\s*([\s\S]*?)```/) || text.match(/\{[\s\S]*\}/);
        return JSON.parse(jsonMatch ? (jsonMatch[1] || jsonMatch[0]) : text);
    } catch {
        return null;
    }
}

/**
 * Analyze a PDF for hidden risks (with RAG context).
 */
async function analyzePdf(pdfText, language = 'en') {
    const startTime = Date.now();

    const langContext = language === 'ta'
        ? 'Respond in Tamil (Kongu dialect) with English technical terms.'
        : language === 'ml'
            ? 'Respond in Malayalam with English technical terms.'
            : 'Respond in English.';

    const responseText = await _callFeatherless([
        { role: 'system', content: SYSTEM_PROMPT },
        {
            role: 'user',
            content: `${langContext}

Analyze this agricultural/environmental document. Cross-reference with your TNAU knowledge base. Focus on HIDDEN RISKS — indirect climate signals, subtle nutrient drift, and rainfall deviations that a farmer would miss.

DOCUMENT TEXT:
${pdfText.substring(0, 15000)}

Respond as JSON:
{
  "summary": "concise 2-3 sentence overview",
  "hidden_risks": [{"label": "risk name", "severity": "low|medium|high", "detail": "explanation"}],
  "recommendations": ["actionable point 1"],
  "fertilizer_ratios": {"N": "kg/acre", "P": "kg/acre", "K": "kg/acre"} or null,
  "explanation": "Why these risks were flagged — cite TNAU data",
  "sources": ["TNAU Crop Production Guide", "IMD rainfall data"]
}`
        }
    ], 2048, 0.3);

    const latencyMs = Date.now() - startTime;
    const parsed = _parseJson(responseText) || {
        summary: responseText,
        hidden_risks: [],
        recommendations: [],
        explanation: 'Direct AI output',
        sources: [],
    };

    return { ...parsed, latency_ms: latencyMs, info_density: _calcDensity(responseText) };
}

/**
 * Answer a voice query with RAG knowledge base.
 * Returns tts_text for direct ElevenLabs piping.
 */
async function answerQuery(transcript, language = 'en', districtContext = null) {
    const startTime = Date.now();

    const langContext = language === 'ta'
        ? 'IMPORTANT: Respond in Tamil (Kongu dialect as spoken in Coimbatore). Use English for technical terms. Response MUST be in the same local dialect used by the farmer.'
        : language === 'ml'
            ? 'IMPORTANT: Respond in Malayalam (Kerala dialect). Use English for technical terms. Response MUST be in the same local dialect used by the farmer.'
            : 'Respond in English. Use simple language a rural farmer can understand.';

    const districtInfo = districtContext
        ? `\nFarmer's location: ${districtContext.name}. Soil: ${districtContext.soil_type}. Avg rainfall: ${districtContext.avg_rainfall_mm}mm.`
        : '';

    console.log(`💬 Farmer query [${language}]: "${transcript}"`);

    const responseText = await _callFeatherless([
        { role: 'system', content: SYSTEM_PROMPT + districtInfo },
        {
            role: 'user',
            content: `${langContext}

Farmer's question: "${transcript}"

Use your TNAU knowledge base to give certified, region-specific advice. Respond concisely (under 100 words). Format as JSON:
{
  "response": "your answer in farmer's dialect",
  "hidden_risks": [{"label": "...", "severity": "low|medium|high"}] or [],
  "explanation": "why this advice — cite TNAU data if relevant",
  "sources": ["TNAU recommendation", "district climate data"]
}`
        }
    ], 512, 0.4);

    const latencyMs = Date.now() - startTime;
    const parsed = _parseJson(responseText) || {
        response: responseText,
        hidden_risks: [],
        explanation: '',
        sources: [],
    };

    const ttsText = parsed.response || responseText;
    console.log(`🔊 TTS text [${language}]: "${ttsText.substring(0, 80)}..."`);

    return {
        ...parsed,
        latency_ms: latencyMs,
        info_density: _calcDensity(responseText),
        tts_text: ttsText,
    };
}

function _calcDensity(text) {
    const words = text.split(/\s+/).length;
    const numbers = (text.match(/\d+\.?\d*/g) || []).length;
    const terms = (text.match(/\b(nitrogen|phosphate|potassium|pH|NPK|rainfall|soil|nutrient|kg|acre|mm|deviation|TNAU|KAU|laterite|loam)\b/gi) || []).length;
    return Math.min(1.0, ((numbers * 2 + terms * 1.5) / Math.max(words, 1)));
}

module.exports = { analyzePdf, answerQuery };
