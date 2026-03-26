const express = require('express');
const db = require('../config/db');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/notifications — Lista notificari ale userului autentificat
router.get('/', auth, async (req, res) => {
  try {
    const { limit = 50 } = req.query;

    const [data] = await db.query(
      `SELECT * FROM notifications
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT ?`,
      [req.user.id, parseInt(limit)]
    );

    const [[{ total }]] = await db.query(
      'SELECT COUNT(*) as total FROM notifications WHERE user_id = ?',
      [req.user.id]
    );

    const [[{ unread_count }]] = await db.query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [req.user.id]
    );

    res.json({ data, total, unread_count });
  } catch (err) {
    console.error('Notifications list error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/notifications/unread-count — Numarul de notificari necitite
router.get('/unread-count', auth, async (req, res) => {
  try {
    const [[{ unread_count }]] = await db.query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [req.user.id]
    );
    res.json({ unread_count });
  } catch (err) {
    console.error('Unread count error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/notifications/:id/read — Marcheaza o notificare ca citita
router.put('/:id/read', auth, async (req, res) => {
  try {
    const [result] = await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Notificare negasita.' });
    }

    res.json({ message: 'Notificare marcata ca citita.' });
  } catch (err) {
    console.error('Mark read error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/notifications/read-all — Marcheaza TOATE notificarile ca citite
router.put('/read-all', auth, async (req, res) => {
  try {
    await db.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE',
      [req.user.id]
    );
    res.json({ message: 'Toate notificarile au fost marcate ca citite.' });
  } catch (err) {
    console.error('Mark all read error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
