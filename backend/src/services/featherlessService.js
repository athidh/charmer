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
        'kg/acre', 'dosage', 'split', 'basal', 'manure', 'compost',
        // Crops + Tamil phonetic variations + STT misinterpretations
        'rice', 'paddy', 'நெல்', 'நெல்லு', 'நெல்லூ',
        'coconut', 'தென்னை', 'தேங்காய்', 'தென்ன', 'தென்னமரம்',
        'banana', 'வாழை', 'வாழ்க்கை', 'வாழைப்பழம்', 'வழ', 'வாழைமரம்',
        'sugarcane', 'கரும்பு', 'கரும்ப', 'கரும்பூ',
        'turmeric', 'மஞ்சள்', 'மஞ்ச', 'மஞ்சள',
        'cotton', 'பருத்தி', 'பருத்த', 'groundnut', 'நிலக்கடலை',
        'tea', 'தேயிலை', 'pepper', 'மிளகு', 'rubber', 'றப்பர்',
        'coffee', 'காப்பி', 'cardamom', 'ஏலக்காய்',
    ],
    'MICRONUTRIENT DEFICIENCY CORRECTIONS': [
        'zinc', 'boron', 'iron', 'manganese', 'calcium', 'deficiency',
        'chlorosis', 'khaira', 'micronutrient', 'foliar', 'spray',
        'துத்தநாகம்', 'போரான்', 'இரும்பு', 'பற்றாக்குறை',
        'yellow', 'leaf', 'tip burn',
    ],
    'COIMBATORE (KONGU) SOIL + CLIMATE PROFILE': [
        'coimbatore', 'kongu', 'red loam', 'noyyal', 'borewell',
        'water table', 'pink bollworm', 'fall armyworm',
        'கோயம்பத்தூர்', 'கொங்கு', 'நொய்யல்', 'சிவப்பு மண்',
        'கோவை', 'கொங்குநாடு',
    ],
    'KERALA (WAYANAD) SOIL + CLIMATE PROFILE': [
        'kerala', 'wayanad', 'laterite', 'monsoon', 'landslide',
        'coffee berry', 'pollinator', 'rain-fed',
        'கேரளா', 'வயநாட்',
    ],
    'HIDDEN RISK DETECTION RULES': [
        'risk', 'rainfall', 'deviation', 'ph', 'organic carbon',
        'water table', 'slope', 'continuous cropping', 'depletion',
        'ஆபத்து', 'மழை', 'மழையளவு',
    ],
    'INTEGRATED PEST MANAGEMENT (IPM)': [
        'pest', 'borer', 'beetle', 'weevil', 'wilt', 'armyworm',
        'trichogramma', 'pheromone', 'trap', 'bio-control', 'ipm',
        'பூச்சி', 'பூச்சிகொல்லி', 'பூச்சிக்கொல்லி', 'பூச்சிமருந்து',
        'bug', 'insect', 'disease', 'fungus',
    ],
};

/**
 * Filter the knowledge base to only include sections relevant to the query.
 * Context modes: CROP_SPECIFIC | FULL_KB_HIGH_INTENT | RISK_ONLY
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

    if (matched.length > 0) {
        const filtered = matched.join('\n\n');
        console.log(`📖 Context [CROP_SPECIFIC]: ${matched.length} section(s) (${filtered.length} chars)`);
        return filtered;
    }

    // ── Length-Based Override: high-intent queries get full KB ──
    if (q.length > 50) {
        console.log(`📖 Context [FULL_KB_HIGH_INTENT]: query is ${q.length} chars (>50), sending full KB (${KNOWLEDGE_FULL.length} chars)`);
        return KNOWLEDGE_FULL;
    }

    // Short no-match → slim Risk+IPM only
    const slimSections = [
        KNOWLEDGE_SECTIONS['HIDDEN RISK DETECTION RULES'],
        KNOWLEDGE_SECTIONS['INTEGRATED PEST MANAGEMENT (IPM)'],
    ].filter(Boolean);

    if (slimSections.length > 0) {
        const slim = slimSections.join('\n\n');
        console.log(`📖 Context [RISK_ONLY]: no match, short query (${slim.length} chars)`);
        return slim;
    }

    console.log(`📖 Context [FULL_KB_FALLBACK]: no sections found (${KNOWLEDGE_FULL.length} chars)`);
    return KNOWLEDGE_FULL;
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

    return `You are CHARMER — an Agricultural Scientist with a Kongu Heart. 40% personality, 60% HARD DATA.

=== YOUR KNOWLEDGE BASE (TNAU/KAU Certified, 5597 chars) ===
${knowledgeContext}
=== END KNOWLEDGE BASE ===

██ REASONING CHAIN — EXECUTE INTERNALLY BEFORE EVERY RESPONSE ██

INTERNAL STEP 1 — IDENTIFY CROP + SOIL:
- Extract the crop name from the farmer's question.
- Extract or infer their soil type. DO NOT say generic "Kongu soil."
  Use SPECIFIC soil names: செம்மண் (Semmann/Red Loam), கரிசல் மண் (Karisal Mann/Black Cotton), சரளை மண் (Saralai Mann/Gravelly).
- If soil type is unclear, ASK: 'உங்க நிலம் செம்மண்ணா, கரிசல் மண்ணா, இல்ல சரளை மண்ணா?' (Is your land red soil, black soil, or gravelly?)

INTERNAL STEP 2 — LOOKUP NPK IN KNOWLEDGE BASE:
- Search the [NPK Tables] above for the farmer's crop.
- Extract the EXACT N, P, K values (kg/acre) and dosage schedule.
- If FOUND: you MUST include at least one specific number in your response.
- If NOT FOUND: proceed to the Apple Logic below.

INTERNAL STEP 3 — TRANSLATE TO KONGU DIALECT:
- Convert the technical data into spoken Kongu Tamil.
- Use the dialect markers from the personality rules below.

██ APPLE LOGIC (OUT-OF-SCOPE CROPS) ██
If the crop is NOT in the Knowledge Base (Apple, Strawberry, Wheat, etc.):
- Tamil: 'ஐயா, ஆப்பிள் நம்ம ஊரு தட்பவெப்பத்துக்கு வராதுங்க. நம்ம செம்மண்ணுக்கு கொய்யா அல்லது வாழை நல்லா வளரும். வாழைக்கு N:100, P:35, K:200 kg/acre போடணும்.' 
  (Sir, Apple won't grow in our climate. For our red soil, Guava or Banana grows well. For Banana: N:100, P:35, K:200 kg/acre.)
- ALWAYS suggest a local alternative WITH its NPK data from your Knowledge Base.
- DO NOT invent values. DO NOT use general knowledge.

██ ANTI-GENERALITY RULE ██
- BANNED phrases: "according to TNAU", "generally", "it is recommended", "Kongu country soil" (without specifying which soil).
- Every response MUST contain at least ONE specific number from the Knowledge Base (kg/acre, %, ratio, mm).
- If you cannot give a technical recommendation from the Knowledge Base above, you have FAILED. Instead, ask the farmer for clarification: 'என்ன பயிர், எத்தனை ஏக்கர்னு சொல்லுங்கப்பா' (Tell me what crop and how many acres, sir).

██ OUTPUT FORMAT ██
1. [Kongu Greeting + SPECIFIC Soil Anchor] — e.g., 'நம்ம கோயம்புத்தூர் செம்மண்ணுல...'
2. [Hard NPK/Soil Data from Knowledge Base with exact numbers]
3. [Closing question about their farm] — e.g., 'எத்தனை ஏக்கர் வச்சிருக்கீங்க?'
- CRITICAL: Do NOT stop until the closing question is generated.

LENGTH: Maximum 150 words. Do NOT truncate mid-thought.
- Respond ONLY in the farmer's script. NO JSON, NO quotes, NO code blocks, NO English labels.${dialectRules}${districtInfo}`;
}

/**
 * Raw axios call to Featherless AI with AbortController, 1500ms clearance sleep,
 * 429→8B instant switch, and TTFT logging for live demo metrics.
 */
async function _callFeatherless(messages, maxTokens = 2048, temperature = 0.3) {
    const apiKey = (process.env.FEATHERLESS_API_KEY || '').trim();
    if (!apiKey) {
        throw new Error('FEATHERLESS_API_KEY is not set in .env');
    }

    const model70B = (process.env.FEATHERLESS_MODEL || 'meta-llama/Meta-Llama-3-70B-Instruct').trim();
    const model8B = (process.env.FEATHERLESS_FALLBACK_MODEL || 'meta-llama/Meta-Llama-3-8B-Instruct').trim();

    console.log(`🤖 Featherless: ${model70B} (${messages.length} msgs, max_tokens=${maxTokens})`);

    /**
     * Make a request with optional AbortController signal.
     * Logs Time-to-First-Token (TTFT) for live demo metrics.
     * On 429: instantly switches to 8B with temp 0.6 (no retry on same model).
     */
    const makeRequest = async (model, timeout, signal = undefined, temp = temperature) => {
        const config = {
            headers: {
                'Authorization': 'Bearer ' + apiKey,
                'Content-Type': 'application/json',
            },
            timeout,
            httpsAgent: keepAliveAgent,
        };
        if (signal) config.signal = signal;

        const body = { model, messages, temperature: temp, max_tokens: maxTokens };
        const reqStart = Date.now();

        try {
            const response = await axios.post(FEATHERLESS_URL, body, config);
            const ttft = Date.now() - reqStart;
            const content = response.data.choices[0]?.message?.content || '';
            console.log(`⏱️ TTFT [${model.split('/').pop()}]: ${ttft}ms (${content.length} chars)`);
            return { content, model, ttft };
        } catch (err) {
            // 429: immediately switch to 8B (don't retry same model)
            if (err.response?.status === 429) {
                console.log(`⏳ 429 on ${model.split('/').pop()} — switching to 8B immediately`);
                const fallbackBody = { ...body, model: model8B, temperature: 0.6 };
                const fallbackStart = Date.now();
                const retry = await axios.post(FEATHERLESS_URL, fallbackBody, {
                    headers: config.headers,
                    timeout: 30000,
                    httpsAgent: keepAliveAgent,
                });
                const ttft = Date.now() - fallbackStart;
                const content = retry.data.choices[0]?.message?.content || '';
                console.log(`⏱️ TTFT [8B-via-429]: ${ttft}ms (${content.length} chars)`);
                return { content, model: model8B, ttft };
            }
            throw err;
        }
    };

    // AbortController: abort 70B when we switch to 8B
    const abort70B = new AbortController();

    try {
        const result = await Promise.race([
            // Primary: 70B model with full 60s timeout (abortable)
            // On abort: returns a never-resolving promise so 8B wins the race
            makeRequest(model70B, 60000, abort70B.signal).catch(err => {
                if (err.name === 'CanceledError' || err.code === 'ERR_CANCELED') {
                    console.log('🚫 70B aborted — yielding race to 8B fallback');
                    return new Promise(() => { }); // never resolves → 8B wins
                }
                throw err; // re-throw real errors
            }),
            // Fallback: wait 8s, ABORT 70B, clearance sleep 1500ms, then fire 8B
            new Promise((resolve, reject) => {
                setTimeout(async () => {
                    console.log(`⏱️ 70B exceeded 8s — aborting to free concurrency units...`);
                    abort70B.abort(); // ← release 4 concurrency units

                    // Mandatory 1500ms clearance sleep: let Featherless server release units
                    console.log(`💤 Clearance sleep 1500ms...`);
                    await new Promise(r => setTimeout(r, 1500));

                    console.log(`🚀 Firing 8B fallback (${model8B}, temp=0.6, max_tokens=150)...`);
                    try {
                        const fallback = await makeRequest(model8B, 30000, undefined, 0.6);
                        resolve(fallback);
                    } catch (e) {
                        reject(e);
                    }
                }, 8000);
            }),
        ]);

        if (result.model !== model70B) {
            console.log(`⚡ Fallback: used 8B (${result.ttft}ms TTFT, ${result.content.length} chars)`);
        } else {
            console.log(`✅ 70B responded in ${result.ttft}ms (${result.content.length} chars)`);
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
 * Short queries (<4 words, no agro keywords) skip 70B and go straight to 8B.
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

    // ── Greeting detection: instant 8B response for greetings ──
    const greetingPatterns = /\b(hello|hi|hey|test|testing)\b|ஹலோ|வணக்கம்|புரியுதா|கேக்குதா|எப்படி|நிவேதா/i;
    const isGreeting = greetingPatterns.test(transcript);

    // ── Short-query routing: skip 70B for small talk / mic tests / greetings ──
    const words = transcript.trim().split(/\s+/);
    const agroKeywords = /coconut|rice|banana|fertilizer|soil|pest|crop|harvest|irrigation|rainfall|paddy|sugarcane|turmeric|tea|pepper|rubber|cotton|groundnut|nitrogen|phosphate|potassium|NPK|pH|acre|hectare|yield|நெல்|தேங்காய்|வாழை|வாழ்க்கை|வாழ்கை|பூச்சி|மரம்|மத்து/i;
    const isShortQuery = (words.length < 4 && !agroKeywords.test(transcript)) || isGreeting;

    if (isGreeting) {
        console.log(`👋 Greeting detected — routing to instant 8B response`);
    } else if (isShortQuery) {
        console.log(`⚡ Short non-agro query (${words.length} words) — routing directly to 8B`);
    }

    // Context-filtered RAG: only send relevant knowledge sections
    const filteredKB = _filterKnowledge(transcript);
    const systemPrompt = _buildSystemPrompt(filteredKB, districtInfo, language);

    // Short queries use 8B directly (temp 0.6, 150 tokens), full queries use the normal 70B→8B race
    const useMaxTokens = isShortQuery ? 150 : 200;
    const useTemp = isShortQuery ? 0.6 : 0.4;

    // Simplified prompt for 8B (fast, blunt, local)
    const prompt8B = `You are a quick Kongu expert. Use the provided data to give a 2-sentence answer. Be blunt and local.\n\n${langContext}\n\nFarmer's question: "${transcript}"\n\nRespond concisely in the farmer's dialect. Do NOT use JSON.`;

    const responseText = await (isShortQuery
        ? _callFeatherlessDirect(
            (process.env.FEATHERLESS_FALLBACK_MODEL || 'meta-llama/Meta-Llama-3-8B-Instruct').trim(),
            [{ role: 'system', content: systemPrompt },
            { role: 'user', content: prompt8B }],
            useMaxTokens, useTemp
        )
        : _callFeatherless(
            [{ role: 'system', content: systemPrompt },
            { role: 'user', content: `${langContext}\n\nFarmer's question: "${transcript}"\n\nUse your TNAU knowledge base to give certified, region-specific advice. Respond concisely (under 60 words) in the farmer's dialect. Do NOT use JSON formatting.` }],
            350, 0.4
        )
    );

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

/**
 * Direct call to a specific model (bypasses the 70B→8B race).
 * Used for short non-agricultural queries to save concurrency.
 */
async function _callFeatherlessDirect(model, messages, maxTokens, temperature) {
    const apiKey = (process.env.FEATHERLESS_API_KEY || '').trim();
    const reqStart = Date.now();
    console.log(`🚀 Direct call: ${model.split('/').pop()} (max_tokens=${maxTokens}, temp=${temperature})`);

    const response = await axios.post(
        FEATHERLESS_URL,
        { model, messages, temperature, max_tokens: maxTokens },
        {
            headers: {
                'Authorization': 'Bearer ' + apiKey,
                'Content-Type': 'application/json',
            },
            timeout: 30000,
            httpsAgent: keepAliveAgent,
        }
    );

    const content = response.data.choices[0]?.message?.content || '';
    console.log(`⏱️ TTFT [${model.split('/').pop()}-direct]: ${Date.now() - reqStart}ms (${content.length} chars)`);
    return content;
}

function _calcDensity(text) {
    const words = text.split(/\s+/).length;
    const numbers = (text.match(/\d+\.?\d*/g) || []).length;
    const terms = (text.match(/\b(nitrogen|phosphate|potassium|pH|NPK|rainfall|soil|nutrient|kg|acre|mm|deviation|TNAU|KAU|laterite|loam)\b/gi) || []).length;
    return Math.min(1.0, ((numbers * 2 + terms * 1.5) / Math.max(words, 1)));
}

module.exports = { analyzePdf, answerQuery };
