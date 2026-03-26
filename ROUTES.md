# EcoLocatie — API Routes

**Base URL:** `http://localhost:3000`

---

## Autentificare & Middleware

| Simbol | Descriere |
|--------|-----------|
| -- | Fara autentificare |
| AUTH | Necesita `Authorization: Bearer <token>` |
| ADMIN | AUTH + `role = 'admin'` |
| UPLOAD | Accepta `multipart/form-data` cu camp `image` |

**JWT:** Header `Authorization: Bearer <token>`, expira dupa 7 zile.

---

## 1. Auth (`/api/auth`) — `src/routes/auth.js`

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| POST | `/api/auth/register` | -- | `{ username, email, password, first_name?, last_name? }` | Inregistrare utilizator nou. Returneaza JWT + user |
| POST | `/api/auth/login` | -- | `{ email, password }` | Autentificare. Returneaza JWT + user |
| GET | `/api/auth/me` | AUTH | — | Profilul utilizatorului curent (toate campurile) |
| PUT | `/api/auth/profile-image` | AUTH + UPLOAD | `image` (multipart) | Upload imagine de profil. Salvata in `uploads/images/users/{id}/avatar.ext` |
| DELETE | `/api/auth/profile-image` | AUTH | — | Sterge imaginea de profil |

**Raspuns register/login:**
```json
{
  "token": "eyJhbG...",
  "user": { "id": 1, "username": "ion", "email": "ion@ex.com", "role": "user" }
}
```

**Raspuns /me:**
```json
{
  "id": 1, "username": "ion", "first_name": "Ion", "last_name": "Popescu",
  "email": "ion@ex.com", "phone": "0740000000", "birth_date": "1995-03-15",
  "role": "user", "is_active": true, "profile_image": null, "created_at": "..."
}
```

---

## 2. Plante (`/api/plants`) — `src/routes/plants.js`

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/plants` | -- | `?search=&sort=name_ro&order=ASC&limit=50&offset=0&lang=ro` | Lista plante cu cautare, sortare, paginare |
| GET | `/api/plants/:id` | -- | `?lang=ro` | Detalii planta cu beneficii, contraindicatii, parti utilizabile, imagini |
| POST | `/api/plants` | ADMIN | vezi mai jos | Adauga planta noua |
| PUT | `/api/plants/:id` | ADMIN | vezi mai jos | Editeaza planta (+ inlocuieste beneficii/contraindicatii/parti) |
| DELETE | `/api/plants/:id` | ADMIN | — | Sterge planta (CASCADE pe beneficii, contraindicatii, parti) |

**Body POST/PUT:**
```json
{
  "name_ro": "Musetel",
  "name_latin": "Matricaria chamomilla",
  "name_en": "Chamomile",
  "family": "Asteraceae",
  "description": "...",
  "description_en": "...",
  "habitat": "...",
  "habitat_en": "...",
  "harvest_period": "Iunie - August",
  "harvest_period_en": "June - August",
  "preparation": "...",
  "preparation_en": "...",
  "image_url": "/images/plants/musetel",
  "icon_color": "#4CAF50",
  "folder_name": "Musetel",
  "usable_parts": ["frunze", "flori"],
  "benefits": ["Calmant natural", "Antiinflamator"],
  "contraindications": ["Alergie la Asteraceae"]
}
```

**Parametrul `lang`** (pe GET list si GET detail):

| Valoare | Comportament |
|---------|-------------|
| `ro` (default) | Campurile `description`, `habitat`, `harvest_period`, `preparation`, `benefits`, `contraindications`, `usable_parts` vin in romana |
| `en` | Aceleasi campuri vin traduse in engleza. **Nu se schimba structura response-ului** — campurile au aceleasi nume, doar continutul e in engleza |

> Frontend-ul trimite `?lang=en` cand utilizatorul schimba limba. Nu apar campuri `_en` in response — API-ul returneaza o singura limba pe request.

**Raspuns GET /api/plants** (`?lang=ro`):
```json
{
  "data": [{ "id": 1, "name_ro": "Musetel", "name_en": "Chamomile", "benefits": ["Calmant natural"], "primary_image": "..." }],
  "total": 19,
  "limit": 50,
  "offset": 0
}
```

**Raspuns GET /api/plants** (`?lang=en`):
```json
{
  "data": [{ "id": 1, "name_ro": "Musetel", "name_en": "Chamomile", "benefits": ["Natural sedative"], "primary_image": "..." }],
  "total": 19,
  "limit": 50,
  "offset": 0
}
```

**Raspuns GET /api/plants/:id** (`?lang=ro`):
```json
{
  "id": 1, "name_ro": "Musetel", "name_latin": "...", "name_en": "Chamomile",
  "family": "Asteraceae",
  "description": "Una dintre cele mai populare plante medicinale...",
  "habitat": "Campuri, marginea drumurilor...",
  "harvest_period": "Mai - Iulie",
  "preparation": "Infuzie: 2-3 lingurite...",
  "icon_color": "#4CAF50", "folder_name": "Musetel",
  "benefits": [{ "id": 1, "benefit": "Calmant natural" }],
  "contraindications": [{ "id": 1, "contraindication": "Alergie la Asteraceae" }],
  "usable_parts": [{ "id": 1, "part": "flori" }],
  "images": ["/images/plants/musetel/1.jpg", "/images/plants/musetel/2.jpg"],
  "primary_image": "/images/plants/musetel/1.jpg"
}
```

**Raspuns GET /api/plants/:id** (`?lang=en`):
```json
{
  "id": 1, "name_ro": "Musetel", "name_latin": "...", "name_en": "Chamomile",
  "family": "Asteraceae",
  "description": "One of the most popular medicinal plants in Romania...",
  "habitat": "Fields, roadsides, uncultivated terrain",
  "harvest_period": "May - July",
  "preparation": "Infusion: 2-3 teaspoons...",
  "icon_color": "#4CAF50", "folder_name": "Musetel",
  "benefits": [{ "id": 1, "benefit": "Calms nerves and reduces anxiety" }],
  "contraindications": [{ "id": 1, "contraindication": "Allergy to Asteraceae family plants" }],
  "usable_parts": [{ "id": 1, "part": "Flowers (flower heads)" }],
  "images": ["/images/plants/musetel/1.jpg", "/images/plants/musetel/2.jpg"],
  "primary_image": "/images/plants/musetel/1.jpg"
}
```

**Sort permis:** `name_ro`, `name_latin`, `name_en`, `created_at`

---

## 3. Puncte de interes / Observatii (`/api/pois`) — `src/routes/pois.js`

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/pois` | -- | `?plant_id=&status=approved&lat=&lng=&radius=10&limit=50&offset=0` | Lista observatii (default: doar approved) |
| GET | `/api/pois/:id` | -- | — | Detalii observatie cu comentarii si imagini |
| POST | `/api/pois` | AUTH + UPLOAD | `plant_id, latitude, longitude, address?, comment?, image?` | Creeaza observatie noua (status: pending) |
| PUT | `/api/pois/:id/status` | ADMIN | `{ "status": "approved" \| "rejected" }` | Aproba/respinge observatie |
| DELETE | `/api/pois/:id` | AUTH (owner sau admin) | — | Sterge observatie + folderul cu imagini |

**Filtrare GPS:** Foloseste formula Haversine. `lat`, `lng` = centrul, `radius` = km.

**Raspuns GET /api/pois:**
```json
{
  "data": [{
    "id": 1, "user_id": 2, "plant_id": 5,
    "latitude": 45.4353, "longitude": 28.008,
    "address": "Str. Brailei 100, Galati",
    "comment": "Gasit langa parc",
    "ai_confidence": 0.940, "status": "approved",
    "plant_name": "Musetel", "name_latin": "...",
    "author": "ion", "primary_image": "/images/poi/1/foto.jpg"
  }]
}
```

**Raspuns GET /api/pois/:id** (include si comentarii):
```json
{
  "id": 1, "...",
  "images": ["/images/poi/1/foto1.jpg", "/images/poi/1/foto2.jpg"],
  "primary_image": "/images/poi/1/foto1.jpg",
  "comments": [{ "id": 1, "content": "Frumos!", "username": "maria", "created_at": "..." }]
}
```

---

## 4. Comentarii (`/api/comments`) — `src/routes/comments.js`

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/comments/poi/:poiId` | -- | `?page=1&limit=20` | Lista comentarii pe o observatie (paginat) |
| POST | `/api/comments/:poiId` | AUTH | `{ "content": "Text comentariu" }` | Adauga comentariu |
| DELETE | `/api/comments/:id` | AUTH (owner sau admin) | — | Sterge comentariu |

**Raspuns GET:**
```json
{
  "data": [{ "id": 1, "content": "...", "username": "ion", "created_at": "..." }],
  "total": 5,
  "page": 1
}
```

---

## 5. AI — Identificare & Chatbot (`/api`) — `src/routes/ai.js`

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| POST | `/api/identify` | UPLOAD | `image` (multipart) | Upload imagine → clasificare AI → returneaza planta |
| POST | `/api/chat` | -- | `{ "question": "...", "user_id?": 1 }` | Intrebare → RAG chatbot (Ollama + Gemma) |

**Raspuns /api/identify (succes):**
```json
{
  "identified": true,
  "confidence": 0.94,
  "plant": {
    "id": 11, "name_ro": "Musetel", "name_latin": "Matricaria chamomilla",
    "description": "...",
    "benefits": ["Calmant natural", "..."],
    "contraindications": ["Alergie la Asteraceae"]
  },
  "image_url": "/uploads/images/1234567890.jpg"
}
```

**Raspuns /api/identify (negasit in DB):**
```json
{
  "identified": false,
  "confidence": 0.67,
  "predicted_class": "Lavanda",
  "message": "Planta nu a fost gasita in baza de date."
}
```

**Raspuns /api/chat:**
```json
{
  "answer": "Musetelul este o planta medicinala cu proprietati calmante...",
  "sources": ["Musetel", "Lavanda"]
}
```

**Flow AI identify:**
1. Imaginea se salveaza temporar in `uploads/images/`
2. Se citeste modelul activ din `config.active_model`
3. Se ruleaza `python classify.py <imagine> <model.h5>`
4. Rezultatul se potriveste cu `plants.folder_name`
5. Se returneaza planta cu beneficii si contraindicatii

---

## 6. Admin (`/api/admin`) — `src/routes/admin.js`

Toate rutele necesita **ADMIN**.

### Utilizatori

| Metoda | Ruta | Query / Body | Descriere |
|--------|------|--------------|-----------|
| GET | `/api/admin/users` | `?search=&role=user\|admin` | Lista utilizatori cu cautare si filtru rol |
| PUT | `/api/admin/users/:id` | `{ "role?": "admin", "is_active?": false }` | Schimba rol si/sau activare cont |
| DELETE | `/api/admin/users/:id` | — | Sterge utilizator (nu pe sine) |

### Moderare POI

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/admin/pois/pending` | Lista observatii in asteptare (pending) |

### Statistici

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/admin/stats` | Dashboard: totalUsers, totalPlants, totalPois, pendingPois, totalComments |

**Raspuns /api/admin/stats:**
```json
{
  "totalUsers": 5,
  "totalPlants": 19,
  "totalPois": 16,
  "pendingPois": 3,
  "totalComments": 8
}
```

### Config Harta

| Metoda | Ruta | Body | Descriere |
|--------|------|------|-----------|
| GET | `/api/admin/config` | — | Toate setarile din tabelul config |
| PUT | `/api/admin/config` | `{ map_center_lat, map_center_lng, map_default_zoom, ... }` | Actualizeaza setarile hartii |

### Model AI

| Metoda | Ruta | Body | Descriere |
|--------|------|------|-----------|
| GET | `/api/admin/model` | — | Modelul activ + lista modele disponibile |
| PUT | `/api/admin/model` | `{ "model": "model_resnet50.h5" }` | Schimba modelul AI activ |

**Modele disponibile:** `model_cnn_custom.h5`, `model_densenet121.h5`, `model_resnet50.h5`

---

## 7. Config public (`/api/config`) — `src/routes/config.js`

| Metoda | Ruta | Acces | Descriere |
|--------|------|-------|-----------|
| GET | `/api/config/map` | -- | Setarile hartii (centru, zoom, bounds, tile URL) — fara autentificare |

**Raspuns:**
```json
{
  "map_center_lat": 45.4353,
  "map_center_lng": 28.008,
  "map_default_zoom": 13,
  "map_max_zoom": 18,
  "map_min_zoom": 10,
  "tile_url": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  "tile_attribution": "...",
  "bounds_north": 45.50, "bounds_south": 45.37,
  "bounds_east": 28.10, "bounds_west": 27.90
}
```

---

## Fisiere statice

| Ruta | Sursa pe disc | Descriere |
|------|---------------|-----------|
| `/uploads/*` | `uploads/` | Imagini uploadate (POI, avatar) |
| `/images/*` | `uploads/images/` | Alias — imagini plante si POI |

---

## Middleware

| Fisier | Descriere |
|--------|-----------|
| `src/middleware/auth.js` | `auth()` — valideaza JWT din header. `adminOnly()` — verifica `role === 'admin'` |
| `src/middleware/upload.js` | Multer — upload imagini JPG/PNG/WebP, max 10MB, salvate in `uploads/images/` |

---

## Coduri de eroare

| Cod | Cand |
|-----|------|
| 400 | Campuri lipsa sau invalide |
| 401 | Token JWT lipsa sau expirat |
| 403 | Lipsa permisiuni (nu e admin / nu e owner) |
| 404 | Resursa negasita |
| 409 | Username/email deja exista |
| 413 | Fisier prea mare (>10MB) |
| 500 | Eroare server |
| 503 | Ollama indisponibil (doar `/api/chat`) |

---

## Rate Limiting

- **100 requesturi** per IP la fiecare **15 minute** pe toate rutele `/api/*`

---

## Structura fisiere src/

```
src/
├── server.js              # Entry point Express
├── ngrok.js               # Tunnel ngrok (development)
├── config/
│   └── db.js              # Pool conexiune MySQL
├── middleware/
│   ├── auth.js            # JWT auth + adminOnly
│   └── upload.js          # Multer image upload
└── routes/
    ├── auth.js            # /api/auth      (register, login, me)
    ├── plants.js          # /api/plants    (CRUD, search, sort)
    ├── pois.js            # /api/pois      (CRUD, GPS filter, moderare)
    ├── comments.js        # /api/comments  (CRUD pe observatii)
    ├── ai.js              # /api/identify  + /api/chat
    ├── admin.js           # /api/admin     (users, stats, config, model)
    └── config.js          # /api/config    (setari harta publice)
```
