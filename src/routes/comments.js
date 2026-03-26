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
      SELECT c.id, c.user_id, c.poi_id, c.content, c.created_at,
             CONCAT(u.first_name, ' ', u.last_name) as author,
             u.username, u.profile_image
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.poi_id = ?
      ORDER BY c.created_at DESC
      LIMIT ? OFFSET ?
    `, [req.params.poiId, parseInt(limit), offset]);

    const [[{ total }]] = await db.query(
      'SELECT COUNT(*) as total FROM comments WHERE poi_id = ?', [req.params.poiId]
    );

    res.json({ data: comments, total });
  } catch (err) {
    console.error('Comments list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/pois/:poiId/comments — Adauga comentariu
router.post('/:poiId/comments', auth, async (req, res) => {
  try {
    const { content } = req.body;
    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Comentariul nu poate fi gol.' });
    }

    const [result] = await db.query(
      'INSERT INTO comments (user_id, poi_id, content) VALUES (?, ?, ?)',
      [req.user.id, req.params.poiId, content.trim()]
    );

    res.status(201).json({ id: result.insertId, message: 'Comentariu adăugat.' });
  } catch (err) {
    console.error('Comment create error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/comments/:id — Sterge comentariu (doar autorul sau admin)
router.delete('/:id', auth, async (req, res) => {
  try {
    const [comments] = await db.query('SELECT user_id FROM comments WHERE id = ?', [req.params.id]);
    if (comments.length === 0) return res.status(404).json({ error: 'Comentariu negăsit.' });

    if (comments[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Nu aveți permisiunea.' });
    }

    await db.query('DELETE FROM comments WHERE id = ?', [req.params.id]);
    res.json({ message: 'Comentariu șters.' });
  } catch (err) {
    console.error('Comment delete error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
