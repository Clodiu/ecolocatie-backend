const express = require('express');
const db = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// GET /api/admin/users
router.get('/users', auth, adminOnly, async (req, res) => {
  try {
    const { search, role } = req.query;
    let query = 'SELECT id, username, first_name, last_name, email, phone, role, is_active, profile_image, created_at FROM users WHERE 1=1';
    let params = [];

    if (search) {
      query += ' AND (username LIKE ? OR email LIKE ? OR first_name LIKE ? OR last_name LIKE ?)';
      params.push(`%${search}%`, `%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (role) {
      query += ' AND role = ?';
      params.push(role);
    }

    query += ' ORDER BY created_at DESC';
    const [users] = await db.query(query, params);
    res.json({ data: users });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/admin/users/:id
router.put('/users/:id', auth, adminOnly, async (req, res) => {
  try {
    const { role, is_active } = req.body;

    if (role !== undefined) {
      if (!['user', 'admin'].includes(role)) {
        return res.status(400).json({ error: 'Rol invalid.' });
      }
      await db.query('UPDATE users SET role = ? WHERE id = ?', [role, req.params.id]);
    }

    if (is_active !== undefined) {
      await db.query('UPDATE users SET is_active = ? WHERE id = ?', [is_active ? 1 : 0, req.params.id]);
    }

    res.json({ message: 'Utilizator actualizat.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/admin/users/:id
router.delete('/users/:id', auth, adminOnly, async (req, res) => {
  try {
    if (req.params.id == req.user.id) {
      return res.status(400).json({ error: 'Nu vă puteți șterge propriul cont.' });
    }
    await db.query('DELETE FROM users WHERE id = ?', [req.params.id]);
    res.json({ message: 'Utilizator șters.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/admin/pois/pending - POI-uri în așteptare
router.get('/pois/pending', auth, adminOnly, async (_req, res) => {
  try {
    const [pois] = await db.query(`
      SELECT poi.*, p.name_ro as plant_name, u.username as author
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      JOIN users u ON poi.user_id = u.id
      WHERE poi.status = 'pending'
      ORDER BY poi.created_at ASC
    `);
    res.json({ data: pois });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/admin/stats - Statistici dashboard
router.get('/stats', auth, adminOnly, async (_req, res) => {
  try {
    const [[{ totalUsers }]] = await db.query('SELECT COUNT(*) as totalUsers FROM users');
    const [[{ activeUsers }]] = await db.query('SELECT COUNT(*) as activeUsers FROM users WHERE is_active = TRUE');
    const [[{ totalPlants }]] = await db.query('SELECT COUNT(*) as totalPlants FROM plants');
    const [[{ totalPois }]] = await db.query('SELECT COUNT(*) as totalPois FROM points_of_interest');
    const [[{ approvedPois }]] = await db.query("SELECT COUNT(*) as approvedPois FROM points_of_interest WHERE status = 'approved'");
    const [[{ pendingPois }]] = await db.query("SELECT COUNT(*) as pendingPois FROM points_of_interest WHERE status = 'pending'");
    const [[{ rejectedPois }]] = await db.query("SELECT COUNT(*) as rejectedPois FROM points_of_interest WHERE status = 'rejected'");
    const [[{ totalComments }]] = await db.query('SELECT COUNT(*) as totalComments FROM comments');

    res.json({ totalUsers, activeUsers, totalPlants, totalPois, approvedPois, pendingPois, rejectedPois, totalComments });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// ============================================
// CONFIG HARTĂ
// ============================================

// GET /api/admin/config - Setările hărții
router.get('/config', auth, adminOnly, async (_req, res) => {
  try {
    const [[config]] = await db.query('SELECT * FROM config WHERE id = 1');
    res.json(config);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/admin/config - Actualizează setările hărții
router.put('/config', auth, adminOnly, async (req, res) => {
  try {
    const { map_center_lat, map_center_lng, map_default_zoom, map_max_zoom, map_min_zoom, tile_url, tile_attribution, bounds_north, bounds_south, bounds_east, bounds_west } = req.body;

    await db.query(
      `UPDATE config SET map_center_lat=?, map_center_lng=?, map_default_zoom=?, map_max_zoom=?, map_min_zoom=?,
       tile_url=?, tile_attribution=?, bounds_north=?, bounds_south=?, bounds_east=?, bounds_west=? WHERE id = 1`,
      [map_center_lat, map_center_lng, map_default_zoom, map_max_zoom, map_min_zoom, tile_url, tile_attribution, bounds_north, bounds_south, bounds_east, bounds_west]
    );

    res.json({ message: 'Configurare hartă actualizată.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// ============================================
// MODEL AI — selectare model de clasificare
// ============================================

const AVAILABLE_MODELS = [
  { filename: 'model_cnn_custom.h5',  name: 'CNN Custom',   description: 'Rețea convoluțională antrenată de la zero. Mai rapidă.' },
  { filename: 'model_densenet121.h5', name: 'DenseNet-121', description: 'Transfer learning DenseNet121. Mai precisă pe seturi mici.' },
  { filename: 'model_resnet50.h5',    name: 'ResNet-50',    description: 'Transfer learning ResNet50. Echilibru viteză/acuratețe.' },
];

// GET /api/admin/model - Modelul activ + lista modelelor disponibile
router.get('/model', auth, adminOnly, async (_req, res) => {
  try {
    const [[config]] = await db.query('SELECT active_model FROM config WHERE id = 1');
    res.json({
      active_model: config.active_model,
      available_models: AVAILABLE_MODELS
    });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/admin/model - Schimbă modelul activ
router.put('/model', auth, adminOnly, async (req, res) => {
  try {
    const { model } = req.body;
    const valid = AVAILABLE_MODELS.map(m => m.filename);

    if (!valid.includes(model)) {
      return res.status(400).json({
        error: 'Model invalid.',
        available: valid
      });
    }

    await db.query('UPDATE config SET active_model = ? WHERE id = 1', [model]);
    res.json({ message: `Modelul activ schimbat la: ${model}`, active_model: model });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
