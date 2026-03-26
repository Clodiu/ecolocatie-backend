const express = require('express');
const db = require('../config/db');

const router = express.Router();

// GET /api/config/map - Setările hărții (public, fără autentificare)
router.get('/map', async (_req, res) => {
  try {
    const [[config]] = await db.query(
      `SELECT map_center_lat, map_center_lng, map_default_zoom, map_max_zoom, map_min_zoom,
              tile_url, tile_attribution, bounds_north, bounds_south, bounds_east, bounds_west
       FROM config WHERE id = 1`
    );

    if (!config) {
      return res.status(404).json({ error: 'Configurarea hărții nu a fost găsită.' });
    }

    res.json(config);
  } catch (err) {
    console.error('Config map error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
