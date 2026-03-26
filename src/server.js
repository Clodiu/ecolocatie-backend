require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');

const app = express();

// ============================================
// MIDDLEWARE
// ============================================
app.use(cors());
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  contentSecurityPolicy: false
}));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servește fișierele uploadate
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/images', express.static(path.join(__dirname, '../uploads/images')));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minute
  max: 1000
});
app.use('/api/', limiter);

// ============================================
// RUTE
// ============================================
const authRoutes = require('./routes/auth');
const plantRoutes = require('./routes/plants');
const poiRoutes = require('./routes/pois');
const commentRoutes = require('./routes/comments');
const aiRoutes = require('./routes/ai');
const adminRoutes = require('./routes/admin');

const userRoutes = require('./routes/users');
const configRoutes = require('./routes/config');
const notificationRoutes = require('./routes/notifications');
const favoriteRoutes = require('./routes/favorites');

app.use('/api/auth', authRoutes);
app.use('/api/plants', plantRoutes);
app.use('/api/pois', poiRoutes);
app.use('/api/pois', commentRoutes);   // GET/POST /api/pois/:id/comments
app.use('/api/comments', commentRoutes); // DELETE /api/comments/:id
app.use('/api', aiRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/config', configRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/favorites', favoriteRoutes);

// ============================================
// RUTA PRINCIPALĂ
// ============================================
app.get('/', (req, res) => {
  res.json({
    name: 'EcoLocație API',
    version: '1.0.0',
    description: 'Identificarea plantelor medicinale din județul Galați',
    endpoints: {
      auth: '/api/auth (register, login, me)',
      plants: '/api/plants (CRUD, search, filter)',
      pois: '/api/pois (CRUD, GPS filter)',
      comments: '/api/comments (CRUD)',
      identify: '/api/identify (POST imagine → AI clasificare)',
      chat: '/api/chat (POST întrebare → RAG Ollama)',
      admin: '/api/admin (users, stats, moderation)'
    }
  });
});

// ============================================
// ERROR HANDLING
// ============================================
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Fișierul este prea mare. Maxim 10MB.' });
  }
  if (err.message?.includes('Doar imagini')) {
    return res.status(400).json({ error: err.message });
  }

  res.status(500).json({ error: 'Eroare internă server.' });
});

// ============================================
// START SERVER
// ============================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
  ╔═══════════════════════════════════════════╗
  ║        🌿 EcoLocație API v1.0.0          ║
  ║   Plante medicinale - Județul Galați      ║
  ╠═══════════════════════════════════════════╣
  ║   Server:  http://localhost:${PORT}          ║
  ║   Docs:    http://localhost:${PORT}/          ║
  ╚═══════════════════════════════════════════╝
  `);
});
