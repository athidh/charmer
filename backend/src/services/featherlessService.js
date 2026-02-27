// src/services/featherlessService.js
// Featherless AI (Llama 3 70B) with context-filtered RAG, keep-alive, and dialect lock
// Uses raw axios — NO OpenAI SDK (prevents 401 from mangled headers)

const axios = require('axios');
const https = require('https');
const fs = require('fs');
const path = require('path');

const FEATHERLESS_URL = 'https://api.featherless.ai/v1/chat/completions';

// ── Keep-Alive Agent — prevents ECONNRESET on long Llama 3 70B responses ──
const keepAliveAgent = new https.Agent({ keepAlive: true });

// ── RAG: Load and index knowledge base by section ──
const KNOWLEDGE_SECTIONS = {};
let KNOWLEDGE_FULL = '';

try {
    const raw = fs.readFileSync(
        path.join(__dirname, '../config/knowledge.txt'), 'utf-8'
    );
    KNOWLEDGE_FULL = raw;

    // Split on section headers: "=== SECTION NAME ==="
    const sectionRegex = /^===\s*(.+?)\s*===$/gm;
    let lastIndex = 0;
    let lastKey = null;
    let match;

    while ((match = sectionRegex.exec(raw)) !== null) {
        if (lastKey) {
            KNOWLEDGE_SECTIONS[lastKey] = raw.substring(lastIndex, match.index).trim();
        }
        lastKey = match[1].trim().toUpperCase();
        lastIndex = match.index;
    }
    // Capture the last section
    if (lastKey) {
        KNOWLEDGE_SECTIONS[lastKey] = raw.substring(lastIndex).trim();
    }

    const sectionNames = Object.keys(KNOWLEDGE_SECTIONS);
    console.log(`📚 Knowledge base loaded: ${raw.length} chars, ${sectionNames.length} sections`);
    console.log(`   Sections: ${sectionNames.join(', ')}`);
} catch (err) {
    console.error('⚠️ Could not load knowledge.txt:', err.message);
    KNOWLEDGE_FULL = 'No knowledge base available.';
}

// ── Context Filter: keyword → relevant sections ──
const SECTION_KEYWORDS = {
    'TNAU CERTIFIED FERTILIZER RECOMMENDATIONS (KG/ACRE)': [
        'fertilizer', 'npk', 'nitrogen', 'phosphate', 'potassium', 'urea',
        'rice', 'sugarcane', 'coconut', 'banana', 'turmeric', 'cotton',
        'groundnut', 'tea', 'pepper', 'rubber', 'coffee', 'cardamom',
        'kg/acre', 'dosage', 'split', 'basal',
    ],
    'MICRONUTRIENT DEFICIENCY CORRECTIONS': [
        'zinc', 'boron', 'iron', 'manganese', 'calcium', 'deficiency',
        'chlorosis', 'khaira', 'micronutrient', 'foliar', 'spray',
    ],
    'COIMBATORE (KONGU) SOIL + CLIMATE PROFILE': [
        'coimbatore', 'kongu', 'red loam', 'noyyal', 'borewell',
        'water table', 'pink bollworm', 'fall armyworm',
    ],
    'KERALA (WAYANAD) SOIL + CLIMATE PROFILE': [
        'kerala', 'wayanad', 'laterite', 'monsoon', 'landslide',
        'coffee berry', 'pollinator', 'rain-fed',
    ],
    'HIDDEN RISK DETECTION RULES': [
        'risk', 'rainfall', 'deviation', 'ph', 'organic carbon',
        'water table', 'slope', 'continuous cropping', 'depletion',
    ],
    'INTEGRATED PEST MANAGEMENT (IPM)': [
        'pest', 'borer', 'beetle', 'weevil', 'wilt', 'armyworm',
        'trichogramma', 'pheromone', 'trap', 'bio-control', 'ipm',
    ],
};

/**
 * Filter the knowledge base to only include sections relevant to the query.
 * Falls back to the full KB if no keyword matches.
 */
function _filterKnowledge(query) {
    const q = (query || '').toLowerCase();
    const matched = [];

    for (const [section, keywords] of Object.entries(SECTION_KEYWORDS)) {
        if (keywords.some(kw => q.includes(kw))) {
            if (KNOWLEDGE_SECTIONS[section]) {
                matched.push(KNOWLEDGE_SECTIONS[section]);
            }
        }
    }

    if (matched.length === 0) {
        // No keyword match → send only Risk Rules + IPM (~1200 chars) for speed
        const slimSections = [
            KNOWLEDGE_SECTIONS['HIDDEN RISK DETECTION RULES'],
            KNOWLEDGE_SECTIONS['INTEGRATED PEST MANAGEMENT (IPM)'],
        ].filter(Boolean);

        if (slimSections.length > 0) {
            const slim = slimSections.join('\n\n');
            console.log(`📖 Context filter: no keyword match, sending Risk+IPM only (${slim.length} chars vs ${KNOWLEDGE_FULL.length} full)`);
            return slim;
        }

        // Ultimate fallback if sections aren't found
        console.log(`📖 Context filter: no sections found, sending full KB (${KNOWLEDGE_FULL.length} chars)`);
        return KNOWLEDGE_FULL;
    }

    const filtered = matched.join('\n\n');
    console.log(`📖 Context filter: ${matched.length} section(s) matched (${filtered.length} chars vs ${KNOWLEDGE_FULL.length} full)`);
    return filtered;
}

// ── System prompt (Kongu Tamil dialect-locked, no JSON wrapping) ──
function _buildSystemPrompt(knowledgeContext, districtInfo = '', language = 'en') {
    const dialectRules = language === 'ta'
        ? `
DIALECT PERSONALITY:
- You are a wise local agrarian expert (பெரியவர்) from Coimbatore. Respond ONLY in Kongu Tamil dialect.
- Use Kongu Tamil markers: 'வச்சிருக்கீங்க' (not வைத்துள்ளீர்கள்), 'பண்றீங்க' (not செய்கிறீர்கள்), 'போடுங்க' (not போடுங்கள்).
- End sentences with the polite 'ங்க' suffix: 'சொல்றேனுங்க', 'பாருங்க', 'குடுங்க'.
- Reference local landmarks: நொய்யல் (Noyyal) basin, கொங்கு நாடு, கன்னிமாரு.
- For Coimbatore farmers: mention Red Loam (சிவப்பு மண்), Zinc/Boron deficiency in local terms (துத்தநாகம்/போரான் பற்றாக்குறை).
- DO NOT use formal/literary Tamil (செந்தமிழ்). Use ONLY spoken Kongu Tamil.
- Keep English technical terms minimal. When unavoidable, explain in Kongu Tamil context.`
        : language === 'ml'
            ? `
DIALECT PERSONALITY:
- You are a wise local agrarian expert from Wayanad. Respond ONLY in Kerala Malayalam dialect.
- Use conversational Malayalam, not formal.
- Reference local context: laterite soil, monsoon patterns, Western Ghats.`
            : '';

    return `You are CHARMER, an expert agrarian AI advisor for the Western Ghats corridor (Coimbatore/Kerala region).

You are an agrarian expert. Using this TNAU data as your primary knowledge source, answer the farmer's query in their local dialect.

=== YOUR KNOWLEDGE BASE (TNAU/KAU Certified) ===
${knowledgeContext}
=== END KNOWLEDGE BASE ===

RESPONSE RULES:
- Limit the response to 3 sentences or roughly 60 words. Prioritize the most critical agricultural action first.
- Respond ONLY in the farmer's script. DO NOT wrap the output in JSON, quotes, or code blocks.
- DO NOT include English labels like 'response:', 'hidden_risks:', 'explanation:', or 'sources:' in your output.
- If a piece of data is missing from the Knowledge Base, use general TNAU principles but stay concise.
- Use ONLY the above knowledge base for factual data (fertilizer ratios, soil profiles, pest management)
- Lead with the MOST CRITICAL hidden risk
- Give SPECIFIC numbers (%, kg/acre, deviations) — cite from the knowledge base
- Use simple language a rural farmer can understand${dialectRules}${districtInfo}`;
}

/**
 * Raw axios call to Featherless AI with explicit Bearer auth and keep-alive.
 * Includes 8B model auto-fallback: if 70B doesn't respond in 8s,
 * fires a parallel request to Llama 3 8B. First result wins.
 */
async function _callFeatherless(messages, maxTokens = 2048, temperature = 0.3) {
    const apiKey = (process.env.FEATHERLESS_API_KEY || '').trim();
    if (!apiKey) {
        throw new Error('FEATHERLESS_API_KEY is not set in .env');
    }

    const model70B = (process.env.FEATHERLESS_MODEL || 'meta-llama/Meta-Llama-3-70B-Instruct').trim();
    const model8B = (process.env.FEATHERLESS_FALLBACK_MODEL || 'meta-llama/Meta-Llama-3-8B-Instruct').trim();

    console.log(`🤖 Featherless: ${model70B} (${messages.length} msgs, max_tokens=${maxTokens})`);

    const makeRequest = (model, timeout) => {
        return axios.post(
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
                timeout,
                httpsAgent: keepAliveAgent,
            }
        ).then(response => {
            const content = response.data.choices[0]?.message?.content || '';
            return { content, model };
        });
    };

    try {
        // Race: 70B with full timeout vs 8B triggered after 8s delay
        const result = await Promise.race([
            // Primary: 70B model with full 60s timeout
            makeRequest(model70B, 60000),
            // Fallback: wait 8s, then fire 8B model request
            new Promise((resolve, reject) => {
                setTimeout(() => {
                    console.log(`⏱️ 70B exceeded 8s, firing 8B fallback (${model8B})...`);
                    makeRequest(model8B, 30000).then(resolve).catch(reject);
                }, 8000);
            }),
        ]);

        if (result.model !== model70B) {
            console.log(`⚡ Fallback: used 8B model (${result.model}) — ${result.content.length} chars`);
        } else {
            console.log(`✅ Featherless 70B: ${result.content.length} chars`);
        }
        return result.content;

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
 * Strip JSON artifacts and English labels from LLM output so ElevenLabs TTS
 * receives clean Tamil/Malayalam/English text.
 */
function _sanitizeForTTS(text) {
    if (!text) return text;

    // If the AI returned a JSON string, try to extract just the "response" value
    try {
        const obj = JSON.parse(text);
        if (obj && typeof obj.response === 'string') {
            text = obj.response;
        }
    } catch { /* not JSON, continue */ }

    // Remove English labels that the LLM might prefix (response:, hidden_risks:, etc.)
    text = text.replace(/\b(response|hidden_risks?|explanation|sources?|severity|label|detail)\s*:/gi, '');

    // Remove leftover JSON punctuation: { } " [ ] and leading colons
    text = text.replace(/[{}"\[\]]/g, '').replace(/^\s*:\s*/gm, '');

    // Remove markdown artifacts (```, **, etc.)
    text = text.replace(/```[\s\S]*?```/g, '').replace(/\*{1,2}/g, '');

    // Collapse extra whitespace
    text = text.replace(/\s{2,}/g, ' ').trim();

    return text;
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

    // PDF analysis uses full knowledge base (broad context needed)
    const systemPrompt = _buildSystemPrompt(KNOWLEDGE_FULL);

    const responseText = await _callFeatherless([
        { role: 'system', content: systemPrompt },
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
 * Answer a voice query with context-filtered RAG knowledge base.
 * Returns tts_text for direct ElevenLabs piping.
 */
async function answerQuery(transcript, language = 'en', districtContext = null) {
    const startTime = Date.now();

    const langContext = language === 'ta'
        ? 'IMPORTANT: Respond ONLY in Kongu Tamil (கொங்கு தமிழ்) as spoken in Coimbatore. Use dialect forms like வச்சிருக்கீங்க, பண்றீங்க, and end with ங்க (e.g., சொல்றேனுங்க). DO NOT use formal Tamil or English sentences. Only Tamil script in the response.'
        : language === 'ml'
            ? 'IMPORTANT: Respond in Malayalam (Kerala dialect). Use English for technical terms only when absolutely needed.'
            : 'Respond in English. Use simple language a rural farmer can understand.';

    const districtInfo = districtContext
        ? `\nFarmer's location: ${districtContext.name}. Soil: ${districtContext.soil_type}. Avg rainfall: ${districtContext.avg_rainfall_mm}mm.`
        : '';

    console.log(`💬 Farmer query [${language}]: "${transcript}"`);

    // Context-filtered RAG: only send relevant knowledge sections
    const filteredKB = _filterKnowledge(transcript);
    const systemPrompt = _buildSystemPrompt(filteredKB, districtInfo, language);

    const responseText = await _callFeatherless([
        { role: 'system', content: systemPrompt },
        {
            role: 'user',
            content: `${langContext}

Farmer's question: "${transcript}"

Use your TNAU knowledge base to give certified, region-specific advice. Respond concisely (under 60 words) in the farmer's dialect. Do NOT use JSON formatting.`
        }
    ], 200, 0.4);

    const latencyMs = Date.now() - startTime;
    const parsed = _parseJson(responseText) || {
        response: responseText,
        hidden_risks: [],
        explanation: '',
        sources: [],
    };

    const ttsText = _sanitizeForTTS(parsed.response || responseText);
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
