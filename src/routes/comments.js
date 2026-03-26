const express = require('express');
const db = require('../config/db');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/pois/:poiId/comments — Lista comentarii per observatie (paginat)
router.get('/:poiId/comments', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const [comments] = await db.query(`
      SELECT c.id, c.user_id, c.poi_id, c.content, c.parent_id, c.created_at,
             u.username, u.profile_image
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.poi_id = ?
      ORDER BY c.created_at ASC
      LIMIT ? OFFSET ?
    `, [req.params.poiId, parseInt(limit), offset]);

    const [[{ total }]] = await db.query(
      'SELECT COUNT(*) as total FROM comments WHERE poi_id = ?', [req.params.poiId]
    );

    res.json({ data: comments, total, page: parseInt(page) });
  } catch (err) {
    console.error('Comments list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/pois/:poiId/comments — Adauga comentariu (cu parent_id optional)
router.post('/:poiId/comments', auth, async (req, res) => {
  try {
    const { content, parent_id } = req.body;
    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Comentariul nu poate fi gol.' });
    }

    const poiId = req.params.poiId;

    // Verificam ca POI-ul exista
    const [pois] = await db.query(
      'SELECT user_id, plant_id FROM points_of_interest WHERE id = ?', [poiId]
    );
    if (pois.length === 0) {
      return res.status(404).json({ error: 'Observatia nu exista.' });
    }

    // Daca parent_id e trimis, verificam ca exista si apartine aceluiasi POI
    if (parent_id) {
      const [parentComments] = await db.query(
        'SELECT id FROM comments WHERE id = ? AND poi_id = ?', [parent_id, poiId]
      );
      if (parentComments.length === 0) {
        return res.status(400).json({ error: 'Comentariul parinte nu exista sau nu apartine acestei observatii.' });
      }
    }

    const [result] = await db.query(
      'INSERT INTO comments (user_id, poi_id, content, parent_id) VALUES (?, ?, ?, ?)',
      [req.user.id, poiId, content.trim(), parent_id || null]
    );

    // Trigger notificare catre autorul POI-ului (daca nu e el insusi)
    const poi = pois[0];
    if (poi.user_id !== req.user.id) {
      try {
        const [[plant]] = await db.query('SELECT name_ro FROM plants WHERE id = ?', [poi.plant_id]);
        const plantName = plant ? plant.name_ro : 'Necunoscut';
        await db.query(
          `INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name)
           VALUES (?, 'poi_commented', ?, ?, ?, ?)`,
          [poi.user_id, 'Comentariu nou', `${req.user.username} a comentat la observatia ta pentru ${plantName}.`, poiId, plantName]
        );
      } catch (notifErr) {
        console.error('Notification create error:', notifErr);
      }
    }

    res.status(201).json({ id: result.insertId, message: 'Comentariu adaugat.' });
  } catch (err) {
    console.error('Comment create error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/comments/:id — Sterge comentariu (doar autorul sau admin)
router.delete('/:id', auth, async (req, res) => {
  try {
    const [comments] = await db.query('SELECT user_id FROM comments WHERE id = ?', [req.params.id]);
    if (comments.length === 0) return res.status(404).json({ error: 'Comentariu negasit.' });

    if (comments[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Nu aveti permisiunea.' });
    }

    await db.query('DELETE FROM comments WHERE id = ?', [req.params.id]);
    res.json({ message: 'Comentariu sters.' });
  } catch (err) {
    console.error('Comment delete error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
