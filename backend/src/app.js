const express = require('express');
const cors = require('cors');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const aiRoutes = require('./routes/aiRoutes');
const climateRoutes = require('./routes/climateRoutes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '50mb' }));

// ── Routes ──
app.use('/api/auth', authRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/climate', climateRoutes);

// Health check
app.get('/', (req, res) => {
    res.send('CHARMER API is running...');
});

// Weather endpoint — retained for micro-climate overlay
const axios = require('axios');
app.get('/api/weather', async (req, res) => {
    try {
        const { lat, lon } = req.query;
        if (!lat || !lon) return res.status(400).json({ error: 'lat and lon required' });
        const apiKey = process.env.WEATHER_API_KEY;
        const url = `${process.env.WEATHER_BASE_URL}?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;
        const response = await axios.get(url);
        const d = response.data;
        res.json({
            temp: `${d.main.temp.toFixed(1)}°C`,
            description: d.weather[0].description,
            icon: d.weather[0].icon,
            humidity: d.main.humidity,
            wind: `${d.wind.speed} m/s`,
            city: d.name,
        });
    } catch (e) {
        res.status(500).json({ error: 'Weather fetch failed', details: e.message });
    }
});

module.exports = app;