const jwt = require('jsonwebtoken');

// Verifică dacă utilizatorul e autentificat
function auth(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Token lipsă. Autentificați-vă.' });
  }
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token invalid sau expirat.' });
  }
}

// Verifică dacă utilizatorul e admin
function adminOnly(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Acces interzis. Necesită rol de administrator.' });
  }
  next();
}

module.exports = { auth, adminOnly };
