const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    role: { type: String, enum: ['user', 'assistant', 'system'], required: true },
    text: { type: String, required: true },
    explanation: { type: String },
    hidden_risks: [{ label: String, severity: String, detail: String }],
    sources: [String],
    latency_ms: { type: Number },
    timestamp: { type: Date, default: Date.now },
});

const sessionSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    messages: [messageSchema],
    pdfAnalyses: [{
        filename: String,
        summary: String,
        hidden_risks: [{ label: String, severity: String }],
        analyzed_at: { type: Date, default: Date.now },
    }],
    districtId: { type: String, default: 'coimbatore' },
    language: { type: String, enum: ['en', 'ta', 'ml'], default: 'en' },
}, {
    timestamps: true,
});

module.exports = mongoose.model('Session', sessionSchema);
