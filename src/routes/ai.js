const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const axios = require('axios');
const db = require('../config/db');
const upload = require('../middleware/upload');

const router = express.Router();

// ============================================
// QUEUE — procesează o singură cerere Ollama la un moment dat
// ============================================
const chatQueue = [];
let chatBusy = false;

function enqueue(task) {
  return new Promise((resolve, reject) => {
    chatQueue.push({ task, resolve, reject });
    processQueue();
  });
}

async function processQueue() {
  if (chatBusy || chatQueue.length === 0) return;
  chatBusy = true;
  const { task, resolve, reject } = chatQueue.shift();
  try {
    const result = await task();
    resolve(result);
  } catch (err) {
    reject(err);
  } finally {
    chatBusy = false;
    processQueue();
  }
}

// POST /api/identify - Upload imagine → model AI → returnează plantă
router.post('/identify', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Imaginea este obligatorie.' });
    }

    const imagePath = path.resolve(req.file.path);
    const pythonScript = path.resolve(__dirname, '../../python/classify.py');

    // Citește modelul activ din config
    const [[config]] = await db.query('SELECT active_model FROM config WHERE id = 1');
    const activeModel = config?.active_model || 'model_cnn_custom.h5';

    // Rulează scriptul Python cu modelul activ
    exec(
      `${process.env.PYTHON_PATH || 'python'} "${pythonScript}" "${imagePath}" "${activeModel}"`,
      { timeout: 30000 },
      async (error, stdout, stderr) => {
        if (error) {
          console.error('Python error:', stderr);
          return res.status(500).json({ error: 'Eroare la clasificarea imaginii.' });
        }

        try {
          const result = JSON.parse(stdout.trim());
          // result = { class: "Musetel", confidence: 0.94 }

          // Caută planta în DB după folder_name
          const [plants] = await db.query(
            'SELECT * FROM plants WHERE folder_name = ?',
            [result.class]
          );

          if (plants.length > 0) {
            const plant = plants[0];
            const [benefits] = await db.query(
              'SELECT benefit FROM plant_benefits WHERE plant_id = ?', [plant.id]
            );
            const [contras] = await db.query(
              'SELECT contraindication FROM plant_contraindications WHERE plant_id = ?', [plant.id]
            );

            res.json({
              identified: true,
              confidence: result.confidence,
              plant: {
                ...plant,
                benefits: benefits.map(b => b.benefit),
                contraindications: contras.map(c => c.contraindication)
              },
              image_url: `/uploads/images/${req.file.filename}`
            });
          } else {
            res.json({
              identified: false,
              confidence: result.confidence,
              predicted_class: result.class,
              message: 'Planta nu a fost găsită în baza de date.'
            });
          }
        } catch (parseErr) {
          console.error('Parse error:', parseErr, 'stdout:', stdout);
          res.status(500).json({ error: 'Eroare la procesarea rezultatului.' });
        }
      }
    );
  } catch (err) {
    console.error('Identify error:', err);
    res.status(500).json({ error: 'Eroare server.' });
  }
});

// POST /api/chat - Chatbot RAG cu Ollama
router.post('/chat', async (req, res) => {
  try {
    const { question, user_id, lang } = req.body;

    if (!question) {
      return res.status(400).json({ error: 'Întrebarea este obligatorie.' });
    }

    // Detectare limba: explicit din body, sau automat din text
    const isEnglish = lang === 'en' || (!lang && /\b(what|how|which|can|does|is|are|the|for|with|plant|benefit|help)\b/i.test(question));
    const language = isEnglish ? 'en' : 'ro';

    // 1. Caută plante relevante în DB pe baza cuvintelor cheie din întrebare
    const searchTerms = question.toLowerCase()
      .replace(/[?!.,]/g, '')
      .split(' ')
      .filter(w => w.length > 3);

    let plantsContext = [];

    // Caută în beneficii, contraindicații, descriere, părți utilizabile
    for (const term of searchTerms) {
      const [results] = await db.query(`
        SELECT DISTINCT p.name_ro, p.name_latin, p.description, p.preparation,
               GROUP_CONCAT(DISTINCT pu.part SEPARATOR '; ') as usable_parts,
               GROUP_CONCAT(DISTINCT pb.benefit SEPARATOR '; ') as benefits,
               GROUP_CONCAT(DISTINCT pc.contraindication SEPARATOR '; ') as contraindications
        FROM plants p
        LEFT JOIN plant_benefits pb ON p.id = pb.plant_id
        LEFT JOIN plant_contraindications pc ON p.id = pc.plant_id
        LEFT JOIN plant_usable_parts pu ON p.id = pu.plant_id
        WHERE pb.benefit LIKE ? OR p.name_ro LIKE ? OR p.description LIKE ?
              OR pu.part LIKE ? OR pc.contraindication LIKE ?
        GROUP BY p.id
        LIMIT 5
      `, [`%${term}%`, `%${term}%`, `%${term}%`, `%${term}%`, `%${term}%`]);

      plantsContext.push(...results);
    }

    // Elimină duplicatele
    const uniquePlants = [...new Map(plantsContext.map(p => [p.name_ro, p])).values()];

    // Dacă nu s-au găsit plante specifice, trimite toate plantele ca context
    if (uniquePlants.length === 0) {
      const [allPlants] = await db.query(`
        SELECT p.name_ro, p.name_latin,
               GROUP_CONCAT(DISTINCT pu.part SEPARATOR '; ') as usable_parts,
               GROUP_CONCAT(DISTINCT pb.benefit SEPARATOR '; ') as benefits
        FROM plants p
        LEFT JOIN plant_benefits pb ON p.id = pb.plant_id
        LEFT JOIN plant_usable_parts pu ON p.id = pu.plant_id
        GROUP BY p.id
      `);
      uniquePlants.push(...allPlants);
    }

    // 2. Construiește contextul pentru Ollama
    const context = uniquePlants.map(p =>
      `Plantă: ${p.name_ro} (${p.name_latin || 'N/A'})
Părți utilizabile: ${p.usable_parts || 'N/A'}
Beneficii: ${p.benefits || 'N/A'}
Contraindicații: ${p.contraindications || 'N/A'}
Preparare: ${p.preparation || 'N/A'}`
    ).join('\n---\n');

    // 3. Trimite la Ollama (prin queue — o singură cerere la un moment dat)
    const ollamaResponse = await enqueue(() =>
      axios.post(`${process.env.OLLAMA_URL}/api/chat`, {
        model: 'gemma3:4b',
        messages: [
          {
            role: 'system',
            content: language === 'en'
              ? `You are an expert assistant on medicinal plants from Romania, especially from Galați county.
Reply ONLY in English.
Reply ONLY based on the information from the context below.
Do NOT invent information. If you cannot find the answer in the context, say honestly that you don't have that information.
ALWAYS mention contraindications when recommending a plant.
Be concise but informative.

DATABASE CONTEXT:
${context}`
              : `Ești un asistent expert în plante medicinale din România, în special cele din județul Galați.
Răspunzi DOAR în limba română.
Răspunzi DOAR pe baza informațiilor din contextul furnizat mai jos.
NU inventezi informații. Dacă nu găsești răspunsul în context, spune sincer că nu ai informații.
Menționează ÎNTOTDEAUNA contraindicațiile când recomanzi o plantă.
Fii concis dar informativ.

CONTEXT DIN BAZA DE DATE:
${context}`
          },
          {
            role: 'user',
            content: question
          }
        ],
        stream: false
      })
    );

    const answer = ollamaResponse.data.message.content;

    // 4. Salvează în istoric
    if (user_id) {
      await db.query(
        'INSERT INTO chat_history (user_id, question, answer) VALUES (?, ?, ?)',
        [user_id, question, answer]
      );
    }

    res.json({
      answer,
      sources: uniquePlants.map(p => p.name_ro)
    });
  } catch (err) {
    console.error('Chat error:', err.message);

    // Fallback dacă Ollama nu e disponibil
    if (err.code === 'ECONNREFUSED') {
      return res.status(503).json({
        error: 'Serviciul AI nu este disponibil momentan.',
        hint: 'Asigurați-vă că Ollama rulează pe server.'
      });
    }

    res.status(500).json({ error: 'Eroare server.' });
  }
});

// GET /api/chat/status - Starea queue-ului
router.get('/chat/status', (req, res) => {
  res.json({ busy: chatBusy, queue_length: chatQueue.length });
});

module.exports = router;
