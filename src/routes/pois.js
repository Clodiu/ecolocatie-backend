const express = require('express');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const db = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = express.Router();

const IMAGE_EXTENSIONS = /\.(jpg|jpeg|png|webp|gif)$/i;
const UPLOADS_ROOT = path.join(__dirname, '../../uploads');

function poiFolderPath(poiId) {
  return path.join(UPLOADS_ROOT, 'images', 'poi', String(poiId));
}

function poiFolderUrl(poiId) {
  return `/images/poi/${poiId}`;
}

function getImagesFromFolder(poiId, limit = null) {
  const dir = poiFolderPath(poiId);
  try {
    let files = fs.readdirSync(dir)
      .filter(f => IMAGE_EXTENSIONS.test(f))
      .sort()
      .map(f => `${poiFolderUrl(poiId)}/${f}`);
    return limit ? files.slice(0, limit) : files;
  } catch {
    return [];
  }
}

// GET /api/pois - Lista POI-uri cu filtrare
router.get('/', async (req, res) => {
  try {
    const { plant_id, status = 'approved', lat, lng, radius = 10, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT poi.*, p.name_ro as plant_name, p.name_latin, p.name_en as plant_name_en,
             p.image_url as plant_image, u.username as author,
             (SELECT COUNT(*) FROM comments c WHERE c.poi_id = poi.id) as comments_count
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      JOIN users u ON poi.user_id = u.id
      WHERE poi.status = ?
    `;
    let params = [status];

    if (plant_id) {
      query += ' AND poi.plant_id = ?';
      params.push(parseInt(plant_id));
    }

    // Filtru pe distanță (Haversine formula) - radius în km
    if (lat && lng) {
      query += ` AND (
        6371 * acos(
          cos(radians(?)) * cos(radians(poi.latitude)) *
          cos(radians(poi.longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(poi.latitude))
        )
      ) <= ?`;
      params.push(parseFloat(lat), parseFloat(lng), parseFloat(lat), parseFloat(radius));
    }

    query += ' ORDER BY poi.created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [pois] = await db.query(query, params);

    for (let poi of pois) {
      poi.images = getImagesFromFolder(poi.id);
      poi.primary_image = poi.images[0] || null;
    }

    res.json({ data: pois });
  } catch (err) {
    console.error('POI list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/pois/:id - Detalii POI
router.get('/:id', async (req, res) => {
  try {
    const [pois] = await db.query(`
      SELECT poi.*, p.name_ro as plant_name, p.name_latin, p.description as plant_description,
             p.preparation, u.username as author
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      JOIN users u ON poi.user_id = u.id
      WHERE poi.id = ?
    `, [req.params.id]);

    if (pois.length === 0) {
      return res.status(404).json({ error: 'Punctul de interes nu a fost găsit.' });
    }

    const poi = pois[0];

    const [comments] = await db.query(`
      SELECT c.*, u.username FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.poi_id = ? ORDER BY c.created_at DESC
    `, [poi.id]);

    poi.images = getImagesFromFolder(poi.id);
    poi.primary_image = poi.images[0] || null;
    poi.comments = comments;

    res.json(poi);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/pois - Creează POI (cu imagine opțională)
router.post('/', auth, upload.single('image'), async (req, res) => {
  try {
    const { plant_id, latitude, longitude, address, comment, ai_confidence } = req.body;

    if (!plant_id || !latitude || !longitude) {
      return res.status(400).json({ error: 'plant_id, latitude și longitude sunt obligatorii.' });
    }

    // Reverse geocoding daca address lipseste
    let finalAddress = address;
    if (!finalAddress) {
      try {
        const geoRes = await axios.get('https://nominatim.openstreetmap.org/reverse', {
          params: { lat: latitude, lon: longitude, format: 'json' },
          headers: { 'User-Agent': 'EcoLocatie/1.0' },
          timeout: 5000
        });
        finalAddress = geoRes.data?.display_name || null;
      } catch { /* geocoding e optional, continuam fara */ }
    }

    const [result] = await db.query(
      'INSERT INTO points_of_interest (user_id, plant_id, latitude, longitude, address, comment, ai_confidence) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [req.user.id, plant_id, latitude, longitude, finalAddress, comment, ai_confidence || null]
    );

    const poiId = result.insertId;
    const folder = poiFolderPath(poiId);
    fs.mkdirSync(folder, { recursive: true });

    // Mută imaginea din temp în folderul POI-ului
    if (req.file) {
      const dest = path.join(folder, req.file.filename);
      fs.renameSync(req.file.path, dest);
    }

    res.status(201).json({ id: poiId, message: 'Punct de interes creat cu succes.' });
  } catch (err) {
    console.error('POI create error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/pois/:id/status - Aprobă/respinge POI (admin)
router.put('/:id/status', auth, adminOnly, async (req, res) => {
  try {
    const { status } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Status invalid. Folosiți approved sau rejected.' });
    }

    await db.query('UPDATE points_of_interest SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ message: `POI ${status === 'approved' ? 'aprobat' : 'respins'} cu succes.` });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/pois/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const [pois] = await db.query('SELECT user_id FROM points_of_interest WHERE id = ?', [req.params.id]);
    if (pois.length === 0) return res.status(404).json({ error: 'POI negăsit.' });

    if (pois[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Nu aveți permisiunea de a șterge acest POI.' });
    }

    await db.query('DELETE FROM points_of_interest WHERE id = ?', [req.params.id]);

    // Șterge folderul cu imaginile POI-ului
    const folder = poiFolderPath(req.params.id);
    if (fs.existsSync(folder)) {
      fs.rmSync(folder, { recursive: true });
    }

    res.json({ message: 'POI șters cu succes.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
