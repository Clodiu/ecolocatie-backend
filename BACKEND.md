# EcoLocatie — Backend Overview

**Stack:** Node.js + Express + MySQL 8
**Port:** 3000 (configurabil din `.env`)
**Autentificare:** JWT (Bearer token, expira 7 zile)

---

## Structura proiect

```
ecolocatie-backend/
├── src/
│   ├── server.js                # Entry point Express
│   ├── ngrok.js                 # Tunnel ngrok (development)
│   ├── config/
│   │   └── db.js                # Pool conexiune MySQL (mysql2/promise)
│   ├── middleware/
│   │   ├── auth.js              # JWT auth + adminOnly guard
│   │   └── upload.js            # Multer — upload imagini (JPG/PNG/WebP, max 10MB)
│   └── routes/
│       ├── auth.js              # Register, login, profil, avatar
│       ├── plants.js            # CRUD plante + localizare lang=ro|en
│       ├── pois.js              # CRUD observatii + filtrare GPS + moderare
│       ├── comments.js          # CRUD comentarii pe observatii
│       ├── ai.js                # Identificare planta (CNN) + Chatbot RAG (Ollama)
│       ├── admin.js             # Useri, stats, config harta, model AI
│       ├── users.js             # Profil public utilizatori
│       └── config.js            # Setari harta (public, fara auth)
├── python/
│   └── classify.py              # Script clasificare imagine cu model CNN/ResNet/DenseNet
├── sql/
│   ├── 001_schema_final.sql     # Schema DB (tabele, indexuri)
│   ├── 002_seed.sql             # Date initiale (19 plante, 5 useri, 16 POI-uri, comentarii)
│   ├── 003_english_translations.sql  # Migrare: coloane _en + traduceri engleza
│   ├── DATABASE.md              # Documentatie DB detaliata
│   └── BACKEND_TODO.md          # Task-uri cerute din frontend
├── uploads/
│   └── images/
│       ├── plants/{slug}/       # Imagini plante (citite din folder, nu din DB)
│       ├── poi/{id}/            # Imagini observatii (uploadate de useri)
│       └── users/{id}/          # Avatare utilizatori
├── .env                         # DB_HOST, DB_USER, DB_PASS, DB_NAME, JWT_SECRET, PORT
├── package.json
├── ROUTES.md                    # Documentatie completa API endpoints
└── SETUP_VM_WINDOWS.md          # Ghid instalare pe Windows
```

---

## Baza de date

**9 tabele:** `users`, `plants`, `plant_usable_parts`, `plant_benefits`, `plant_contraindications`, `points_of_interest`, `comments`, `chat_history`, `config`

**Relatii principale:**
- `users` 1→N `points_of_interest` N←1 `plants`
- `users` 1→N `comments` N←1 `points_of_interest`
- `plants` 1→N `plant_benefits` / `plant_contraindications` / `plant_usable_parts`

**Multilingv:** Toate tabelele de plante au coloane `_en` (description_en, benefit_en, etc.). API-ul returneaza o singura limba per request via `?lang=ro|en`.

---

## API Endpoints (rezumat)

| Grup | Prefix | Fisier | Descriere |
|------|--------|--------|-----------|
| Auth | `/api/auth` | auth.js | Register, login, /me, avatar upload/delete |
| Plante | `/api/plants` | plants.js | CRUD, search, sort, `?lang=ro\|en` |
| Observatii | `/api/pois` | pois.js | CRUD, filtrare GPS (Haversine), moderare status |
| Comentarii | `/api/pois/:id/comments` | comments.js | Lista/adauga comentarii; DELETE pe `/api/comments/:id` |
| AI | `/api/identify`, `/api/chat` | ai.js | Upload imagine → CNN classify; Intrebare → RAG chatbot |
| Admin | `/api/admin` | admin.js | Useri, stats, config harta, model AI |
| Config | `/api/config/map` | config.js | Setari harta (public) |

> Documentatie completa cu request/response examples: [ROUTES.md](ROUTES.md)

---

## Imagini

Imaginile **nu sunt stocate in DB** — sunt pe disc in `uploads/images/`. API-ul citeste folderul si returneaza:
- `primary_image` — primul fisier (sortat alfabetic)
- `images[]` — toate fisierele din folder

| Tip | Folder | Cine il creeaza |
|-----|--------|-----------------|
| Plante | `uploads/images/plants/{slug}/` | Manual (dataset AI) |
| Observatii | `uploads/images/poi/{id}/` | Upload la POST /api/pois |
| Avatare | `uploads/images/users/{id}/` | Upload la PUT /api/auth/profile-image |

---

## AI Pipeline

1. **Identificare planta:** POST `/api/identify` cu imagine → `python/classify.py` ruleaza modelul CNN → match cu `plants.folder_name` → returneaza planta
2. **Chatbot RAG:** POST `/api/chat` → Ollama (Gemma) cu context din DB plante → raspuns
3. **Modele disponibile:** `model_cnn_custom.h5`, `model_densenet121.h5`, `model_resnet50.h5` (switch din admin)

---

## Comenzi

```bash
npm install          # Instaleaza dependintele
npm run dev          # Start cu nodemon (auto-restart)
npm start            # Start productie
npm run db:init      # Creeaza schema + seed DB
```

**Dupa db:init, ruleaza migrarea traduceri:**
```bash
mysql -u root -p ecolocatie < sql/003_english_translations.sql
```

---

## Middleware

| Middleware | Descriere |
|-----------|-----------|
| CORS | Permite toate originile |
| Helmet | Security headers (CSP dezactivat pentru imagini cross-origin) |
| Rate Limit | 100 req / 15 min per IP pe `/api/*` |
| JWT Auth | `auth()` pe rute protejate, `adminOnly()` pe rute admin |
| Multer | Upload imagini max 10MB (JPG/PNG/WebP) |
