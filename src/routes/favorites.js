const express = require('express');
const db = require('../config/db');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/favorites — Lista plant_id-uri favorite ale userului
router.get('/', auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT plant_id FROM favorites WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json({ data: rows.map(r => r.plant_id) });
  } catch (err) {
    console.error('Favorites list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/favorites/:plantId — Adauga planta la favorite
router.post('/:plantId', auth, async (req, res) => {
  try {
    await db.query(
      'INSERT IGNORE INTO favorites (user_id, plant_id) VALUES (?, ?)',
      [req.user.id, req.params.plantId]
    );
    res.status(201).json({ message: 'Planta adaugata la favorite.' });
  } catch (err) {
    console.error('Add favorite error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/favorites/:plantId — Sterge planta din favorite
router.delete('/:plantId', auth, async (req, res) => {
  try {
    const [result] = await db.query(
      'DELETE FROM favorites WHERE user_id = ? AND plant_id = ?',
      [req.user.id, req.params.plantId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Favorit negasit.' });
    }

    res.json({ message: 'Planta stearsa din favorite.' });
  } catch (err) {
    console.error('Delete favorite error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
