// src/controllers/climateController.js
// Hyper-local district-level climate data for Western Ghats / Coimbatore corridor

const districtData = require('../config/districtSeedData.json');
const axios = require('axios');

/**
 * GET /api/climate/district/:districtId
 * Returns hyper-local soil + rainfall data with real-time weather overlay.
 */
exports.getDistrictData = async (req, res) => {
    try {
        const { districtId } = req.params;
        const district = districtData.districts?.[districtId];

        if (!district) {
            return res.status(404).json({
                error: 'District not found',
                available: Object.keys(districtData.districts || {}),
            });
        }

        // Fetch real-time weather overlay
        let currentWeather = null;
        try {
            const apiKey = process.env.WEATHER_API_KEY;
            if (apiKey && apiKey !== 'your_openweathermap_api_key_here') {
                const url = `${process.env.WEATHER_BASE_URL}?lat=${district.lat}&lon=${district.lon}&appid=${apiKey}&units=metric`;
                const weatherRes = await axios.get(url, { timeout: 5000 });
                const d = weatherRes.data;
                currentWeather = {
                    temp: `${d.main.temp.toFixed(1)}°C`,
                    description: d.weather[0].description,
                    humidity: d.main.humidity,
                    wind: `${d.wind.speed} m/s`,
                };
            }
        } catch (e) {
            // Weather is optional — don't fail the request
        }

        res.json({
            ...district,
            current_weather: currentWeather,
            data_source: 'TNAU Agro Climate Research Centre / Kerala Agricultural University',
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch district data', details: err.message });
    }
};
