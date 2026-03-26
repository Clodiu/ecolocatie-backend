# EcoLocatie — Clasificare plante medicinale

## Prezentare generala

Clasificarea imaginilor se face prin scriptul `classify.py`, apelat din backend-ul Node.js ca subprocess. Scriptul primeste calea spre o imagine, o proceseaza cu modelul Keras `.h5` activ si returneaza predictia ca JSON pe `stdout`.

Imaginea temporara este stearsa automat dupa clasificare (cleanup in `ai.js`).

---

## Modele disponibile

| Fisier | Arhitectura | Default | Descriere |
|--------|-------------|---------|-----------|
| `model_densenet121.h5` | DenseNet-121 | **Da** | Transfer learning din DenseNet121 preantrenat pe ImageNet. Mai precisa pe seturi mici. |
| `model_resnet50.h5` | ResNet-50 | Nu | Transfer learning din ResNet50. Bun echilibru intre viteza si acuratete. |
| `model_cnn_custom.h5` | CNN custom | Nu | Retea convolutionala antrenata de la zero pe datasetul propriu. Mai usoara, mai rapida. |

Toate modelele clasifica aceleasi **19 clase** (plante medicinale), in aceeasi ordine:

```
Aloe Vera, Brusture, Coada soricelului, Coltii babei, Floarea soarelui,
Galbenele, Hibiscus, Iasomie, Lavanda, Menta, Musetel, Papadie, Pelin,
Rostopasca, Salvie, Sunatoare, Trandafir, Urzica, Valeriana
```

---

## Cum functioneaza clasificarea

```
Frontend  →  POST /api/identify (multipart, campul "image")
                ↓
            Node.js (ai.js)
            1. Salveaza imaginea temporar in uploads/images/
            2. Citeste modelul activ din tabelul config (campul active_model)
            3. Apeleaza: python classify.py <cale_imagine> <model.h5>
                ↓
            Python (classify.py)
            1. Incarca modelul .h5 cu TensorFlow/Keras
            2. Redimensioneaza imaginea la input_shape al modelului
            3. Normalizeaza pixelii (÷ 255)
            4. Ruleaza model.predict()
            5. Returneaza JSON pe stdout:
               {
                 "class": "Musetel",
                 "confidence": 0.94,
                 "model_used": "model_densenet121.h5",
                 "all_predictions": { "Musetel": 0.94, "Papadie": 0.03, ... }
               }
                ↓
            Node.js
            1. Sterge imaginea temporara de pe disc
            2. Parseaza JSON din stdout
            3. Cauta planta in DB dupa folder_name
            4. Returneaza raspunsul complet catre frontend
```

---

## Preprocesarea imaginii

1. **Redimensionare** — la dimensiunea input-ului modelului (detectata automat din `model.input_shape`)
2. **Normalizare** — valorile pixelilor impartite la 255 → interval `[0.0, 1.0]`
3. **Batch dimension** — array-ul e extins cu `np.expand_dims(..., axis=0)` pentru a simula un batch de 1 imagine

---

## Apelarea scriptului

```bash
# Sintaxa
python classify.py <cale_imagine> [model.h5]

# Exemple
python classify.py /tmp/upload.jpg model_densenet121.h5
python classify.py /tmp/upload.jpg model_resnet50.h5
python classify.py /tmp/upload.jpg model_cnn_custom.h5

# Daca modelul lipseste, se foloseste model_densenet121.h5 (default)
python classify.py /tmp/upload.jpg
```

---

## Schimbarea modelului activ (admin)

Modelul activ se stocheaza in tabelul `config` (campul `active_model`). Adminul il poate schimba din panoul de administrare fara a reporni serverul.

```
GET  /api/admin/model        → returneza modelul activ + lista modelelor disponibile
PUT  /api/admin/model        → { "model": "model_resnet50.h5" } → schimba modelul activ
```

La fiecare request `/api/identify`, backend-ul citeste `active_model` din DB si il trimite ca argument scriptului Python.

---

## Raspuns JSON

**Succes (planta gasita in DB):**
```json
{
  "identified": true,
  "confidence": 0.94,
  "plant": {
    "id": 11,
    "name_ro": "Musetel",
    "name_latin": "Matricaria chamomilla",
    "description": "...",
    "benefits": ["Calmant natural", "..."],
    "contraindications": ["Alergie la Asteraceae", "..."]
  }
}
```

**Succes (planta negasita in DB):**
```json
{
  "identified": false,
  "confidence": 0.67,
  "predicted_class": "Lavanda",
  "message": "Planta nu a fost gasita in baza de date."
}
```

---

## Chatbot RAG (Ollama)

Chatbot-ul foloseste `gemma3:1b` prin Ollama cu Retrieval-Augmented Generation:

| Parametru | Valoare | Descriere |
|-----------|---------|-----------|
| Model | `gemma3:1b` | Google Gemma 3, 1B parametri (~815MB) |
| `num_predict` | 400 | Maxim tokeni in raspuns |
| `num_ctx` | 4096 | Dimensiune context window |
| `temperature` | 0.4 | Creativitate scazuta — raspunsuri factuale |
| `keep_alive` | 30m | Modelul ramane in RAM 30 min dupa ultima cerere |
| Queue | Da | O singura cerere Ollama la un moment dat |
| Timeout | 60s | Per cerere |

**Flow:**
1. Extrage cuvinte cheie din intrebare (cu stemming romanesc + normalizare diacritice)
2. Cauta plante relevante in DB (`COLLATE utf8mb4_general_ci` pentru match fara diacritice)
3. Construieste context din plantele gasite (beneficii, contraindicatii, preparare, etc.)
4. Trimite la Ollama ca system prompt + intrebarea userului
5. Salveaza in `chat_history` daca `user_id` e trimis

**Endpoint-uri:**
```
POST /api/chat          → { "question": "...", "user_id?": 1, "lang?": "ro" }
GET  /api/chat/status   → { "busy": false, "queue_length": 0 }
```

**Detectie limba:** automat din cuvinte cheie englezesti, sau explicit cu `lang: "en"/"ro"`.

---

## Structura fisiere

```
python/
├── classify.py            # Script clasificare (apelat de Node.js)
├── model_densenet121.h5   # Model default — DenseNet-121 (transfer learning)
├── model_resnet50.h5      # ResNet-50 (transfer learning)
├── model_cnn_custom.h5    # CNN antrenat de la zero
└── CLASSIFICATION.md      # Aceasta documentatie
```

---

## Dependente Python

```
tensorflow >= 2.10
numpy
pillow
```

Instalare:
```bash
pip install tensorflow numpy pillow
```

---

## Dependente Ollama (chatbot)

```bash
# Instalare model
ollama pull gemma3:1b

# Verificare ca ruleaza
curl http://localhost:11434/api/tags
```

Ollama trebuie sa ruleze pe `localhost:11434` (configurabil prin `OLLAMA_URL` in `.env`).
