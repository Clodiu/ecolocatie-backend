const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const db = require('../config/db');
const upload = require('../middleware/upload');

const router = express.Router();

// Warmup — preîncarcă modelul în RAM la pornirea serverului
(async () => {
  try {
    await axios.post(`${process.env.OLLAMA_URL}/api/chat`, {
      model: 'gemma3:1b',
      messages: [{ role: 'user', content: 'test' }],
      stream: false,
      options: { num_predict: 1, num_thread: 6 }
    }, { timeout: 60000 });
    console.log('✅ Ollama gemma3:1b preîncărcat');
  } catch { console.log('⚠️ Ollama warmup eșuat (va încărca la prima cerere)'); }
})();

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
    const activeModel = config?.active_model || 'model_densenet121.h5';

    // Rulează scriptul Python cu modelul activ
    exec(
      `${process.env.PYTHON_PATH || 'python'} "${pythonScript}" "${imagePath}" "${activeModel}"`,
      { timeout: 30000 },
      async (error, stdout, stderr) => {
        // Sterge imaginea temporara dupa clasificare
        try { fs.unlinkSync(imagePath); } catch {}

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
              }
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

    // 1. Cauta plante relevante in DB pe baza cuvintelor cheie din intrebare
    // Normalizeaza diacritice: musetelul -> musteelul, dar si musetel -> mustetel
    function removeDiacritics(str) {
      return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    }

    // Sterge sufixe romanesti comune (articole, cazuri)
    function stemRo(word) {
      return word
        .replace(/(ului|ului|ilor|elor|ului)$/i, '')
        .replace(/(ul|ua|ea|le|ii|ei)$/i, '')
        .replace(/(a|e|i)$/i, '');
    }

    const rawTerms = removeDiacritics(question.toLowerCase())
      .replace(/[?!.,;:'"]/g, '')
      .split(/\s+/)
      .filter(w => w.length > 3);

    // Pastreaza atat termenul original cat si cel fara sufix
    const searchTerms = [...new Set(rawTerms.flatMap(w => {
      const stemmed = stemRo(w);
      return stemmed.length >= 3 ? [w, stemmed] : [w];
    }))];

    let plantsContext = [];

    // Cauta in beneficii, contraindicatii, descriere — collate general_ci ignora diacritice
    const likeConditions = searchTerms.map(() =>
      '(pb.benefit COLLATE utf8mb4_general_ci LIKE ? OR p.name_ro COLLATE utf8mb4_general_ci LIKE ? OR p.name_en COLLATE utf8mb4_general_ci LIKE ? OR p.description COLLATE utf8mb4_general_ci LIKE ?)'
    ).join(' OR ');

    const likeParams = searchTerms.flatMap(t => {
      const term = `%${t}%`;
      return [term, term, term, term];
    });

    if (likeConditions) {
      const [results] = await db.query(`
        SELECT DISTINCT p.name_ro, p.name_latin, p.description, p.preparation,
               GROUP_CONCAT(DISTINCT pu.part SEPARATOR '; ') as usable_parts,
               GROUP_CONCAT(DISTINCT pb.benefit SEPARATOR '; ') as benefits,
               GROUP_CONCAT(DISTINCT pc.contraindication SEPARATOR '; ') as contraindications
        FROM plants p
        LEFT JOIN plant_benefits pb ON p.id = pb.plant_id
        LEFT JOIN plant_contraindications pc ON p.id = pc.plant_id
        LEFT JOIN plant_usable_parts pu ON p.id = pu.plant_id
        WHERE ${likeConditions}
        GROUP BY p.id
        LIMIT 3
      `, likeParams);
      plantsContext.push(...results);
    }

    const uniquePlants = [...new Map(plantsContext.map(p => [p.name_ro, p])).values()].slice(0, 3);

    // Daca nu s-au gasit plante specifice, cauta si dupa numele plantei direct
    if (uniquePlants.length === 0) {
      const nameConditions = searchTerms.map(() => '(p.name_ro COLLATE utf8mb4_general_ci LIKE ? OR p.name_en COLLATE utf8mb4_general_ci LIKE ? OR p.name_latin COLLATE utf8mb4_general_ci LIKE ?)').join(' OR ');
      const nameParams = searchTerms.flatMap(t => { const term = `%${t}%`; return [term, term, term]; });

      if (nameConditions) {
        const [results] = await db.query(`
          SELECT DISTINCT p.name_ro, p.name_latin, p.description, p.preparation,
                 GROUP_CONCAT(DISTINCT pu.part SEPARATOR '; ') as usable_parts,
                 GROUP_CONCAT(DISTINCT pb.benefit SEPARATOR '; ') as benefits,
                 GROUP_CONCAT(DISTINCT pc.contraindication SEPARATOR '; ') as contraindications
          FROM plants p
          LEFT JOIN plant_benefits pb ON p.id = pb.plant_id
          LEFT JOIN plant_contraindications pc ON p.id = pc.plant_id
          LEFT JOIN plant_usable_parts pu ON p.id = pu.plant_id
          WHERE ${nameConditions}
          GROUP BY p.id
          LIMIT 3
        `, nameParams);
        uniquePlants.push(...results);
      }
    }

    // Daca tot nu s-a gasit nimic, trimite lista scurta de plante disponibile
    if (uniquePlants.length === 0) {
      const [allPlants] = await db.query(`
        SELECT p.name_ro, p.name_latin,
               GROUP_CONCAT(DISTINCT pb.benefit SEPARATOR '; ') as benefits
        FROM plants p
        LEFT JOIN plant_benefits pb ON p.id = pb.plant_id
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
        model: 'gemma3:1b',
        messages: [
          {
            role: 'system',
            content: language === 'en'
              ? `You are an expert assistant STRICTLY about medicinal plants from Romania, especially from Galați county.
Reply ONLY in English.
Reply ONLY based on the information from the context below.
Do NOT invent information. If you cannot find the answer in the context, say honestly that you don't have that information.
ALWAYS mention contraindications when recommending a plant.
Keep answers SHORT — maximum 3-4 sentences. No long explanations.
IMPORTANT: If the question is NOT about medicinal plants, herbal medicine, or phytotherapy, reply ONLY with: "I can only answer questions about medicinal plants."

DATABASE CONTEXT:
${context}`
              : `Ești un asistent expert STRICT în plante medicinale din România, în special cele din județul Galați.
Răspunzi DOAR în limba română.
Răspunzi DOAR pe baza informațiilor din contextul furnizat mai jos.
NU inventezi informații. Dacă nu găsești răspunsul în context, spune sincer că nu ai informații.
Menționează ÎNTOTDEAUNA contraindicațiile când recomanzi o plantă.
Răspunsuri SCURTE — maxim 3-4 propoziții. Fără explicații lungi.
IMPORTANT: Dacă întrebarea NU este despre plante medicinale, fitoterapie sau remedii naturale, răspunde DOAR cu: "Pot răspunde doar la întrebări despre plante medicinale."

CONTEXT DIN BAZA DE DATE:
${context}`
          },
          {
            role: 'user',
            content: question
          }
        ],
        stream: false,
        keep_alive: '30m',
        options: {
          num_predict: 200,
          num_ctx: 4096,
          temperature: 0.4,
          num_thread: 6
        }
      }, { timeout: 60000 })
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
