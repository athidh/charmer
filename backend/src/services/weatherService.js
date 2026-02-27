const axios = require('axios');

const getCurrentTemperature = async (lat, lon) => {
    try {
        const apiKey = process.env.WEATHER_API_KEY;
        const baseUrl = process.env.WEATHER_BASE_URL;

        if (!apiKey) {
            console.warn("⚠️ No Weather API key found. Using fallback temp.");
            return 30;
        }

        // Construct the OpenWeatherMap URL
        // units=metric ensures the temp is in Celsius instead of Kelvin
        const url = `${baseUrl}?lat=${lat}&lon=${lon}&units=metric&appid=${apiKey}`;
        
        const response = await axios.get(url);
        
        // OpenWeatherMap stores the temperature inside the "main" object
        const realTemp = response.data.main.temp; 
        
        console.log(`🌤️ Live Weather Fetched: ${realTemp}°C at [${lat}, ${lon}]`);
        return realTemp;

    } catch (error) {
        // If the key isn't active yet, OpenWeatherMap throws a 401 error
        if (error.response && error.response.status === 401) {
            console.error("❌ Weather API Error: 401 Unauthorized. Your key might still be activating!");
        } else {
            console.error("❌ Weather API Error:", error.message);
        }
        
        // Fallback temperature so your app doesn't crash during the hackathon
        return 30; 
    }
};

module.exports = { getCurrentTemperature };