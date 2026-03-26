const express = require('express');
const db = require('../config/db');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/users/:id/plants — Plantele unice observate de user (din POI-uri)
router.get('/:id/plants', auth, async (req, res) => {
  try {
    const [plants] = await db.query(`
      SELECT p.*,
             COUNT(poi.id) as observation_count,
             MAX(poi.created_at) as last_observation_date
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      WHERE poi.user_id = ?
      GROUP BY p.id
      ORDER BY last_observation_date DESC
    `, [req.params.id]);

    res.json({
      data: plants.map(p => ({
        plant: {
          id: p.id, name_ro: p.name_ro, name_latin: p.name_latin, name_en: p.name_en,
          family: p.family, image_url: p.image_url, icon_color: p.icon_color
        },
        observation_count: p.observation_count,
        last_observation_date: p.last_observation_date
      }))
    });
  } catch (err) {
    console.error('User plants error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/users/:id/history — Toate POI-urile user-ului, sortate desc
router.get('/:id/history', auth, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const [pois] = await db.query(`
      SELECT poi.*, p.name_ro as plant_name, p.name_latin, p.name_en,
             p.image_url as plant_image, p.icon_color
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      WHERE poi.user_id = ?
      ORDER BY poi.created_at DESC
      LIMIT ? OFFSET ?
    `, [req.params.id, parseInt(limit), parseInt(offset)]);

    const [[{ total }]] = await db.query(
      'SELECT COUNT(*) as total FROM points_of_interest WHERE user_id = ?', [req.params.id]
    );

    res.json({ data: pois, total });
  } catch (err) {
    console.error('User history error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/users/:id/plants/:plantId — Sterge toate POI-urile user-ului pentru o planta
router.delete('/:id/plants/:plantId', auth, async (req, res) => {
  try {
    if (parseInt(req.params.id) !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Nu aveți permisiunea.' });
    }

    const [result] = await db.query(
      'DELETE FROM points_of_interest WHERE user_id = ? AND plant_id = ?',
      [req.params.id, req.params.plantId]
    );

    res.json({ deleted: result.affectedRows, message: 'Observațiile au fost șterse.' });
  } catch (err) {
    console.error('Delete user plants error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
