/**
 * EcoLocatie — ngrok tunnel
 *
 * Pornește serverul Express + un tunel ngrok pentru acces public.
 * Folosire:  node src/ngrok.js
 */
require('dotenv').config();
const ngrok = require('ngrok');

const PORT = process.env.PORT || 3000;

(async () => {
  // 1. Pornește serverul Express (side-effect: ascultă pe PORT)
  require('./server');

  // 2. Pornește tunelul ngrok
  try {
    const url = await ngrok.connect({
      addr: PORT,
      // Dacă ai un authtoken ngrok, pune-l în .env ca NGROK_AUTHTOKEN
      authtoken: process.env.NGROK_AUTHTOKEN || undefined,
    });

    console.log(`
  ╔═══════════════════════════════════════════════════════╗
  ║            ngrok — tunel public activ                ║
  ╠═══════════════════════════════════════════════════════╣
  ║   URL public:  ${url.padEnd(36)}║
  ║   API docs:    ${(url + '/docs').padEnd(36)}║
  ║   Local:       http://localhost:${String(PORT).padEnd(21)}║
  ╚═══════════════════════════════════════════════════════╝
    `);
  } catch (err) {
    console.error('ngrok error:', err.message);
    console.log('\nServerul local funcționează, dar tunelul ngrok nu a pornit.');
    console.log('Verifică: npm install ngrok && npx ngrok authtoken <TOKEN>');
  }
})();
