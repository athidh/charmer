// Speech output demo — tests LLM + TTS pipeline
// Run: node test_speech.js

const axios = require('axios');
const fs = require('fs');

const BASE = 'http://localhost:3000/api';

async function demo() {
    console.log('\n🎙️ === CHARMER Speech Output Demo ===\n');

    // Test 1: Direct text query to see if LLM + context filter works
    console.log('─── Test 1: Coconut fertilizer query (should trigger CROP_SPECIFIC) ───');

    try {
        // We'll simulate a voice query by creating a minimal WAV file
        // But first let's test the featherless service directly by calling answerQuery
        // through the analyze endpoint with a simple text query

        // Actually let's test the full pipeline by hitting voice-query with a real WAV
        // Create a minimal WAV header (silence) - just to test the pipeline flow
        const sampleRate = 16000;
        const duration = 1; // 1 second of silence
        const numSamples = sampleRate * duration;
        const dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
        const fileSize = 44 + dataSize;

        const wav = Buffer.alloc(fileSize);
        wav.write('RIFF', 0);
        wav.writeUInt32LE(fileSize - 8, 4);
        wav.write('WAVE', 8);
        wav.write('fmt ', 12);
        wav.writeUInt32LE(16, 16);
        wav.writeUInt16LE(1, 20); // PCM
        wav.writeUInt16LE(1, 22); // mono
        wav.writeUInt32LE(sampleRate, 24);
        wav.writeUInt32LE(sampleRate * 2, 28);
        wav.writeUInt16LE(2, 32);
        wav.writeUInt16LE(16, 34);
        wav.write('data', 36);
        wav.writeUInt32LE(dataSize, 40);
        // rest is zeros = silence

        console.log('📤 Sending silent WAV to test STT handling...');

        const FormData = require('form-data');
        const form = new FormData();
        form.append('audio', wav, { filename: 'test.wav', contentType: 'audio/wav' });
        form.append('language', 'ta');

        const resp = await axios.post(`${BASE}/ai/voice-query`, form, {
            headers: form.getHeaders(),
            timeout: 60000,
            responseType: 'text',
        });

        const lines = resp.data.split('\n').filter(l => l.trim());
        for (const line of lines) {
            const chunk = JSON.parse(line);
            console.log(`  Phase: ${chunk.phase}`);
            if (chunk.phase === 'stt') {
                console.log(`  📝 Transcript: "${chunk.transcript}"`);
                console.log(`  🔍 Language: ${chunk.detected_language}`);
            }
            if (chunk.phase === 'complete') {
                console.log(`  🤖 Response: "${chunk.response}"`);
                console.log(`  🔊 Audio: ${chunk.audio_base64 ? chunk.audio_base64.substring(0, 40) + '...' : 'none'}`);
                console.log(`  ⏱️ Latency: ${chunk.latency_ms}ms`);
                console.log(`  📊 Breakdown: STT=${chunk.breakdown?.stt_ms}ms, LLM=${chunk.breakdown?.llm_ms}ms, TTS=${chunk.breakdown?.tts_ms}ms`);

                // Save audio to file if available
                if (chunk.audio_base64) {
                    const audioBuffer = Buffer.from(chunk.audio_base64, 'base64');
                    fs.writeFileSync('demo_output.mp3', audioBuffer);
                    console.log(`  💾 Audio saved to demo_output.mp3 (${audioBuffer.length} bytes)`);
                }
            }
            if (chunk.phase === 'error') {
                console.log(`  ❌ Error: ${chunk.error}`);
            }
        }
    } catch (err) {
        console.log(`  ❌ ${err.message}`);
        if (err.response?.data) {
            console.log(`  Details:`, typeof err.response.data === 'string'
                ? err.response.data.substring(0, 200)
                : JSON.stringify(err.response.data).substring(0, 200));
        }
    }

    // Test 2: Direct fertilizer calc (no audio needed, instant)
    console.log('\n─── Test 2: Fertilizer Calculator (instant, no LLM needed) ───');
    try {
        const resp = await axios.post(`${BASE}/ai/fertilizer-calc`, {
            acreage: 5,
            crop_type: 'coconut',
            district: 'coimbatore',
            soil_type: 'red_loam',
        });
        console.log(`  🧪 NPK for 5 acres coconut on red loam:`);
        console.log(`     N: ${resp.data.fertilizer_ratios.N} kg`);
        console.log(`     P: ${resp.data.fertilizer_ratios.P} kg`);
        console.log(`     K: ${resp.data.fertilizer_ratios.K} kg`);
        console.log(`  📝 ${resp.data.explanation}`);
    } catch (err) {
        console.log(`  ❌ ${err.message}`);
    }

    console.log('\n✅ Demo complete!\n');
}

demo();
