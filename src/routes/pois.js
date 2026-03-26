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

// Helper: trimite notificari catre toti adminii
async function notifyAdmins(type, title, message, poiId, plantName) {
  try {
    const [admins] = await db.query("SELECT id FROM users WHERE role = 'admin'");
    for (const admin of admins) {
      await db.query(
        `INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [admin.id, type, title, message, poiId, plantName]
      );
    }
  } catch (err) {
    console.error('Notify admins error:', err);
  }
}

// GET /api/pois - Lista POI-uri cu filtrare
router.get('/', async (req, res) => {
  try {
    const { plant_id, user_id, status = 'approved', search, lat, lng, radius = 10, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT poi.*, p.name_ro as plant_name, p.name_latin, p.name_en as plant_name_en,
             p.image_url as plant_image, p.icon_color, u.username as author,
             (SELECT COUNT(*) FROM comments c WHERE c.poi_id = poi.id) as comment_count
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

    if (user_id) {
      query += ' AND poi.user_id = ?';
      params.push(parseInt(user_id));
    }

    if (search) {
      query += ' AND (p.name_ro LIKE ? OR p.name_latin LIKE ? OR p.name_en LIKE ? OR poi.comment LIKE ? OR poi.address LIKE ?)';
      const s = `%${search}%`;
      params.push(s, s, s, s, s);
    }

    // Filtru pe distanta (Haversine formula) - radius in km
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

    // Total count for pagination
    let countQuery = `
      SELECT COUNT(*) as total
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      WHERE poi.status = ?
    `;
    let countParams = [status];
    if (plant_id) { countQuery += ' AND poi.plant_id = ?'; countParams.push(parseInt(plant_id)); }
    if (user_id) { countQuery += ' AND poi.user_id = ?'; countParams.push(parseInt(user_id)); }
    if (search) {
      countQuery += ' AND (p.name_ro LIKE ? OR p.name_latin LIKE ? OR p.name_en LIKE ? OR poi.comment LIKE ? OR poi.address LIKE ?)';
      const s = `%${search}%`;
      countParams.push(s, s, s, s, s);
    }

    const [[{ total }]] = await db.query(countQuery, countParams);

    res.json({ data: pois, total });
  } catch (err) {
    console.error('POI list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/pois/:id - Detalii POI
router.get('/:id', async (req, res) => {
  try {
    const [pois] = await db.query(`
      SELECT poi.*, p.name_ro as plant_name, p.name_latin, p.name_en as plant_name_en,
             p.description as plant_description, p.preparation, p.icon_color,
             u.username as author,
             (SELECT COUNT(*) FROM comments c WHERE c.poi_id = poi.id) as comment_count
      FROM points_of_interest poi
      JOIN plants p ON poi.plant_id = p.id
      JOIN users u ON poi.user_id = u.id
      WHERE poi.id = ?
    `, [req.params.id]);

    if (pois.length === 0) {
      return res.status(404).json({ error: 'Punctul de interes nu a fost gasit.' });
    }

    const poi = pois[0];

    const [comments] = await db.query(`
      SELECT c.id, c.user_id, c.poi_id, c.content, c.parent_id, c.created_at,
             u.username, u.profile_image
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.poi_id = ? ORDER BY c.created_at ASC
    `, [poi.id]);

    poi.images = getImagesFromFolder(poi.id);
    poi.primary_image = poi.images[0] || null;
    poi.comments = comments;

    res.json(poi);
  } catch (err) {
    console.error('POI detail error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/pois - Creeaza POI (cu imagine optionala + campuri noi)
router.post('/', auth, upload.single('image'), async (req, res) => {
  try {
    const {
      plant_id, latitude, longitude, address, comment, ai_confidence,
      description, habitat, harvest_period, benefits, contraindications,
      description_en, habitat_en, harvest_period_en, benefits_en, contraindications_en,
      comment_en
    } = req.body;

    if (!plant_id || !latitude || !longitude) {
      return res.status(400).json({ error: 'plant_id, latitude si longitude sunt obligatorii.' });
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
      `INSERT INTO points_of_interest
        (user_id, plant_id, latitude, longitude, address, comment, ai_confidence,
         description, habitat, harvest_period, benefits, contraindications,
         description_en, habitat_en, harvest_period_en, benefits_en, contraindications_en, comment_en)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [req.user.id, plant_id, latitude, longitude, finalAddress,
       comment || null, ai_confidence || null,
       description || null, habitat || null, harvest_period || null,
       benefits || null, contraindications || null,
       description_en || null, habitat_en || null, harvest_period_en || null,
       benefits_en || null, contraindications_en || null, comment_en || null]
    );

    const poiId = result.insertId;
    const folder = poiFolderPath(poiId);
    fs.mkdirSync(folder, { recursive: true });

    // Muta imaginea din temp in folderul POI-ului si sterge originalul
    if (req.file) {
      const dest = path.join(folder, req.file.filename);
      fs.copyFileSync(req.file.path, dest);
      try { fs.unlinkSync(req.file.path); } catch {}
    }

    // Obtine numele plantei pentru notificari
    let plantName = 'Necunoscut';
    try {
      const [[plant]] = await db.query('SELECT name_ro FROM plants WHERE id = ?', [plant_id]);
      if (plant) plantName = plant.name_ro;
    } catch {}

    // Notificare: confirmare catre autor ca observatia e in asteptare
    try {
      await db.query(
        `INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name)
         VALUES (?, 'poi_pending', ?, ?, ?, ?)`,
        [req.user.id, 'Observatie in asteptare', `Observatia ta pentru ${plantName} a fost trimisa si asteapta aprobare.`, poiId, plantName]
      );
    } catch (notifErr) {
      console.error('Notification error:', notifErr);
    }

    // Notificare: informeaza toti adminii ca exista un POI nou
    await notifyAdmins('poi_created', 'Observatie noua', `${req.user.username} a adaugat o observatie pentru ${plantName}.`, poiId, plantName);

    res.status(201).json({ id: poiId, message: 'Punct de interes creat cu succes.' });
  } catch (err) {
    console.error('POI create error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/pois/:id - Editeaza observatia proprie
router.put('/:id', auth, async (req, res) => {
  try {
    const poiId = req.params.id;

    // Verifica ca POI-ul exista si userul e owner
    const [pois] = await db.query('SELECT user_id, plant_id FROM points_of_interest WHERE id = ?', [poiId]);
    if (pois.length === 0) {
      return res.status(404).json({ error: 'Observatia nu exista.' });
    }
    if (pois[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Doar autorul poate edita observatia.' });
    }

    const {
      comment, description, habitat, harvest_period, benefits, contraindications,
      comment_en, description_en, habitat_en, harvest_period_en, benefits_en, contraindications_en
    } = req.body;

    await db.query(
      `UPDATE points_of_interest SET
        comment = COALESCE(?, comment),
        description = COALESCE(?, description),
        habitat = COALESCE(?, habitat),
        harvest_period = COALESCE(?, harvest_period),
        benefits = COALESCE(?, benefits),
        contraindications = COALESCE(?, contraindications),
        comment_en = COALESCE(?, comment_en),
        description_en = COALESCE(?, description_en),
        habitat_en = COALESCE(?, habitat_en),
        harvest_period_en = COALESCE(?, harvest_period_en),
        benefits_en = COALESCE(?, benefits_en),
        contraindications_en = COALESCE(?, contraindications_en),
        status = 'pending'
       WHERE id = ?`,
      [comment || null, description || null, habitat || null, harvest_period || null,
       benefits || null, contraindications || null,
       comment_en || null, description_en || null, habitat_en || null,
       harvest_period_en || null, benefits_en || null, contraindications_en || null,
       poiId]
    );

    // Notificare catre admini
    let plantName = 'Necunoscut';
    try {
      const [[plant]] = await db.query('SELECT name_ro FROM plants WHERE id = ?', [pois[0].plant_id]);
      if (plant) plantName = plant.name_ro;
    } catch {}

    await notifyAdmins('poi_edited', 'Observatie editata', `${req.user.username} a editat observatia pentru ${plantName}. Necesita re-moderare.`, poiId, plantName);

    res.json({ message: 'Observatie actualizata. Statusul a fost resetat la pending.' });
  } catch (err) {
    console.error('POI edit error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/pois/:id/status - Aproba/respinge POI (admin) + notificare + reason
router.put('/:id/status', auth, adminOnly, async (req, res) => {
  try {
    const { status, reason } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Status invalid. Folositi approved sau rejected.' });
    }

    const poiId = req.params.id;

    // Obtine info despre POI
    const [pois] = await db.query(
      'SELECT user_id, plant_id FROM points_of_interest WHERE id = ?', [poiId]
    );
    if (pois.length === 0) {
      return res.status(404).json({ error: 'POI negasit.' });
    }

    await db.query('UPDATE points_of_interest SET status = ? WHERE id = ?', [status, poiId]);

    // Notificare catre autorul POI-ului
    const poi = pois[0];
    try {
      const [[plant]] = await db.query('SELECT name_ro FROM plants WHERE id = ?', [poi.plant_id]);
      const plantName = plant ? plant.name_ro : 'Necunoscut';

      const type = status === 'approved' ? 'poi_approved' : 'poi_rejected';
      const title = status === 'approved' ? 'Observatie aprobata' : 'Observatie respinsa';
      const message = status === 'approved'
        ? `Observatia ta pentru ${plantName} a fost aprobata.`
        : `Observatia ta pentru ${plantName} a fost respinsa.${reason ? ' Motiv: ' + reason : ''}`;

      await db.query(
        `INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name, reason)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [poi.user_id, type, title, message, poiId, plantName, reason || null]
      );
    } catch (notifErr) {
      console.error('Notification error:', notifErr);
    }

    res.json({ message: `POI ${status === 'approved' ? 'aprobat' : 'respins'} cu succes.` });
  } catch (err) {
    console.error('POI status error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/pois/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const [pois] = await db.query('SELECT user_id FROM points_of_interest WHERE id = ?', [req.params.id]);
    if (pois.length === 0) return res.status(404).json({ error: 'POI negasit.' });

    if (pois[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Nu aveti permisiunea de a sterge acest POI.' });
    }

    // Sterge notificarile asociate
    await db.query('DELETE FROM notifications WHERE poi_id = ?', [req.params.id]);

    await db.query('DELETE FROM points_of_interest WHERE id = ?', [req.params.id]);

    // Sterge folderul cu imaginile POI-ului
    const folder = poiFolderPath(req.params.id);
    if (fs.existsSync(folder)) {
      fs.rmSync(folder, { recursive: true });
    }

    res.json({ message: 'POI sters cu succes.' });
  } catch (err) {
    console.error('POI delete error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
