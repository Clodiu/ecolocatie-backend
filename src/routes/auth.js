const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const db = require('../config/db');
const { auth } = require('../middleware/auth');
const upload = require('../middleware/upload');

const UPLOADS_ROOT = path.join(__dirname, '../../uploads');

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { username, first_name, last_name, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email și parola sunt obligatorii.' });
    }

    // Verifică dacă username sau email există deja
    const [existing] = await db.query(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Username-ul sau emailul este deja folosit.' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      'INSERT INTO users (username, first_name, last_name, email, password_hash) VALUES (?, ?, ?, ?, ?)',
      [username, first_name || null, last_name || null, email, password_hash]
    );

    const token = jwt.sign(
      { id: result.insertId, username, role: 'user' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.status(201).json({ token, user: { id: result.insertId, username, first_name, last_name, email, role: 'user', profile_image: null } });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email și parolă sunt obligatorii.' });
    }

    const [users] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Email sau parolă incorectă.' });
    }

    const user = users[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Email sau parolă incorectă.' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );

    res.json({
      token,
      user: { id: user.id, username: user.username, email: user.email, role: user.role, first_name: user.first_name, last_name: user.last_name, profile_image: user.profile_image }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT id, username, first_name, last_name, email, phone, birth_date, role, is_active, profile_image, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (users.length === 0) {
      return res.status(404).json({ error: 'Utilizator negăsit.' });
    }
    res.json(users[0]);
  } catch (err) {
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// PUT /api/auth/profile-image - Upload imagine de profil
router.put('/profile-image', auth, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Imaginea este obligatorie.' });
    }

    const userDir = path.join(UPLOADS_ROOT, 'images', 'users', String(req.user.id));
    fs.mkdirSync(userDir, { recursive: true });

    // Sterge imaginea veche daca exista
    try {
      const existing = fs.readdirSync(userDir);
      for (const file of existing) {
        fs.unlinkSync(path.join(userDir, file));
      }
    } catch { /* folderul nou, nimic de sters */ }

    // Muta imaginea in folderul userului
    const ext = path.extname(req.file.originalname);
    const filename = `avatar${ext}`;
    fs.renameSync(req.file.path, path.join(userDir, filename));

    const profileUrl = `/images/users/${req.user.id}/${filename}`;
    await db.query('UPDATE users SET profile_image = ? WHERE id = ?', [profileUrl, req.user.id]);

    res.json({ profile_image: profileUrl, message: 'Imagine de profil actualizată.' });
  } catch (err) {
    console.error('Profile image error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// DELETE /api/auth/profile-image - Sterge imaginea de profil
router.delete('/profile-image', auth, async (req, res) => {
  try {
    const userDir = path.join(UPLOADS_ROOT, 'images', 'users', String(req.user.id));
    if (fs.existsSync(userDir)) {
      fs.rmSync(userDir, { recursive: true });
    }
    await db.query('UPDATE users SET profile_image = NULL WHERE id = ?', [req.user.id]);
    res.json({ message: 'Imagine de profil ștearsă.' });
  } catch (err) {
    console.error('Delete profile image error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

module.exports = router;
