const express = require('express');
const router = express.Router();
const climateController = require('../controllers/climateController');

// GET /api/climate/district/:districtId
router.get('/district/:districtId', climateController.getDistrictData);

module.exports = router;
