const express = require('express');
const fs = require('fs');
const path = require('path');
const db = require('../config/db');
const { auth, adminOnly } = require('../middleware/auth');

const IMAGE_EXTENSIONS = /\.(jpg|jpeg|png|webp|gif)$/i;

// Citește imaginile dintr-un folder de pe disc și returnează URL-urile
function getImagesFromFolder(folderUrl, limit = null) {
  if (!folderUrl) return [];
  const absPath = path.join(__dirname, '../../uploads', folderUrl);
  try {
    let files = fs.readdirSync(absPath)
      .filter(f => IMAGE_EXTENSIONS.test(f))
      .sort()
      .map(f => `${folderUrl}/${f}`);
    return limit ? files.slice(0, limit) : files;
  } catch {
    return [];
  }
}

// Localizează un obiect plantă pe baza limbii
// lang='en': description_en → description, apoi șterge câmpurile _en
// lang='ro' (default): șterge câmpurile _en, păstrează cele românești
function localizePlant(plant, lang) {
  const p = { ...plant };
  const fields = ['description', 'habitat', 'harvest_period', 'preparation'];
  // Câmpul unificat "name" — preia din limba cerută
  p.name = lang === 'en' ? (p.name_en || p.name_ro) : p.name_ro;
  if (lang === 'en') {
    for (const f of fields) {
      if (p[`${f}_en`]) p[f] = p[`${f}_en`];
    }
  }
  // Șterge câmpurile _en din response
  for (const f of fields) delete p[`${f}_en`];
  return p;
}

// Localizează un array de obiecte din sub-tabele (benefits, contraindications, usable_parts)
function localizeList(rows, roField, enField, lang) {
  return rows.map(row => {
    const r = { ...row };
    if (lang === 'en' && r[enField]) r[roField] = r[enField];
    delete r[enField];
    return r;
  });
}

const router = express.Router();

// GET /api/plants - Lista plante cu filtrare, sortare, căutare
router.get('/', async (req, res) => {
  try {
    const { search, sort = 'name_ro', order = 'ASC', limit = 50, offset = 0, lang = 'ro' } = req.query;

    // Validare sort columns
    const allowedSort = ['name_ro', 'name_latin', 'name_en', 'created_at'];
    const sortCol = allowedSort.includes(sort) ? sort : 'name_ro';
    const sortOrder = order.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';

    let query = 'SELECT * FROM plants';
    let params = [];

    if (search) {
      query += ' WHERE name_ro LIKE ? OR name_latin LIKE ? OR name_en LIKE ? OR description LIKE ?';
      const term = `%${search}%`;
      params = [term, term, term, term];
    }

    query += ` ORDER BY ${sortCol} ${sortOrder} LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), parseInt(offset));

    const [plants] = await db.query(query, params);

    // Adaugă beneficiile și prima imagine la fiecare plantă
    for (let i = 0; i < plants.length; i++) {
      const [benefits] = await db.query(
        'SELECT benefit, benefit_en FROM plant_benefits WHERE plant_id = ?', [plants[i].id]
      );
      const localized = localizePlant(plants[i], lang);
      localized.benefits = localizeList(benefits, 'benefit', 'benefit_en', lang).map(b => b.benefit);
      localized.images = getImagesFromFolder(localized.image_url);
      localized.primary_image = localized.images[0] || null;
      plants[i] = localized;
    }

    // Total pentru paginare
    let countQuery = 'SELECT COUNT(*) as total FROM plants';
    let countParams = [];
    if (search) {
      countQuery += ' WHERE name_ro LIKE ? OR name_latin LIKE ? OR name_en LIKE ? OR description LIKE ?';
      const term = `%${search}%`;
      countParams = [term, term, term, term];
    }
    const [countResult] = await db.query(countQuery, countParams);

    res.json({
      data: plants,
      total: countResult[0].total,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (err) {
    console.error('Plants list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/plants/:id - Detalii plantă
router.get('/:id', async (req, res) => {
  try {
    const { lang = 'ro' } = req.query;

    const [plants] = await db.query('SELECT * FROM plants WHERE id = ?', [req.params.id]);
    if (plants.length === 0) {
      return res.status(404).json({ error: 'Planta nu a fost găsită.' });
    }

    const plant = localizePlant(plants[0], lang);

    const [benefits] = await db.query(
      'SELECT id, benefit, benefit_en FROM plant_benefits WHERE plant_id = ?', [plant.id]
    );
    const [contraindications] = await db.query(
      'SELECT id, contraindication, contraindication_en FROM plant_contraindications WHERE plant_id = ?', [plant.id]
    );
    const [usableParts] = await db.query(
      'SELECT id, part, part_en FROM plant_usable_parts WHERE plant_id = ?', [plant.id]
    );

    plant.benefits = localizeList(benefits, 'benefit', 'benefit_en', lang);
    plant.contraindications = localizeList(contraindications, 'contraindication', 'contraindication_en', lang);
    plant.usable_parts = localizeList(usableParts, 'part', 'part_en', lang);
    plant.images = getImagesFromFolder(plant.image_url);
    plant.primary_image = plant.images[0] || null;

    res.json(plant);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/plants - Adaugă plantă (admin)
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const { name_ro, name_latin, name_en, family, description, description_en, habitat, habitat_en, harvest_period, harvest_period_en, preparation, preparation_en, image_url, icon_color, folder_name, benefits, contraindications, usable_parts } = req.body;

    if (!name_ro || !folder_name) {
      return res.status(400).json({ error: 'Numele și folder_name sunt obligatorii.' });
    }

    const [result] = await db.query(
      'INSERT INTO plants (name_ro, name_latin, name_en, family, description, description_en, habitat, habitat_en, harvest_period, harvest_period_en, preparation, preparation_en, image_url, icon_color, folder_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name_ro, name_latin, name_en, family, description, description_en, habitat, habitat_en, harvest_period, harvest_period_en, preparation, preparation_en, image_url, icon_color || '#4CAF50', folder_name]
    );

    const plantId = result.insertId;

    // Adaugă părți utilizabile
    if (usable_parts && usable_parts.length > 0) {
      for (const part of usable_parts) {
        await db.query('INSERT INTO plant_usable_parts (plant_id, part) VALUES (?, ?)', [plantId, part]);
      }
    }

    // Adaugă beneficii
    if (benefits && benefits.length > 0) {
      for (const benefit of benefits) {
        await db.query('INSERT INTO plant_benefits (plant_id, benefit) VALUES (?, ?)', [plantId, benefit]);
      }
    }

    // Adaugă contraindicații
    if (contraindications && contraindications.length > 0) {
      for (const contra of contraindications) {
        await db.query('INSERT INTO plant_contraindications (plant_id, contraindication) VALUES (?, ?)', [plantId, contra]);
      }
    }

    res.status(201).json({ id: plantId, message: 'Plantă adăugată cu succes.' });
  } catch (err) {
    console.error('Plant create error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/plants/:id - Editează plantă (admin)
router.put('/:id', auth, adminOnly, async (req, res) => {
  try {
    const { name_ro, name_latin, name_en, family, description, description_en, habitat, habitat_en, harvest_period, harvest_period_en, preparation, preparation_en, image_url, icon_color, usable_parts, benefits, contraindications } = req.body;

    await db.query(
      'UPDATE plants SET name_ro=?, name_latin=?, name_en=?, family=?, description=?, description_en=?, habitat=?, habitat_en=?, harvest_period=?, harvest_period_en=?, preparation=?, preparation_en=?, image_url=?, icon_color=? WHERE id=?',
      [name_ro, name_latin, name_en, family, description, description_en, habitat, habitat_en, harvest_period, harvest_period_en, preparation, preparation_en, image_url, icon_color, req.params.id]
    );

    // Actualizează părți utilizabile (înlocuiește tot)
    if (usable_parts) {
      await db.query('DELETE FROM plant_usable_parts WHERE plant_id = ?', [req.params.id]);
      for (const part of usable_parts) {
        await db.query('INSERT INTO plant_usable_parts (plant_id, part) VALUES (?, ?)', [req.params.id, part]);
      }
    }

    // Actualizează beneficii
    if (benefits) {
      await db.query('DELETE FROM plant_benefits WHERE plant_id = ?', [req.params.id]);
      for (const benefit of benefits) {
        await db.query('INSERT INTO plant_benefits (plant_id, benefit) VALUES (?, ?)', [req.params.id, benefit]);
      }
    }

    // Actualizează contraindicații
    if (contraindications) {
      await db.query('DELETE FROM plant_contraindications WHERE plant_id = ?', [req.params.id]);
      for (const contra of contraindications) {
        await db.query('INSERT INTO plant_contraindications (plant_id, contraindication) VALUES (?, ?)', [req.params.id, contra]);
      }
    }

    res.json({ message: 'Plantă actualizată cu succes.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/plants/:id - Șterge plantă (admin)
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    await db.query('DELETE FROM plants WHERE id = ?', [req.params.id]);
    res.json({ message: 'Plantă ștearsă cu succes.' });
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
