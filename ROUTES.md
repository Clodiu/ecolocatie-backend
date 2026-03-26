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
| POST | `/api/auth/register` | -- + UPLOAD | `username, email, password, first_name?, last_name?, phone?, birth_date?, image?` (multipart) | Inregistrare utilizator nou cu imagine de profil optionala. Returneaza JWT + user |
| POST | `/api/auth/login` | -- | `{ email, password }` | Autentificare. Returneaza JWT + user. Verifica `is_active` |
| GET | `/api/auth/me` | AUTH | — | Profilul utilizatorului curent (toate campurile) |
| PUT | `/api/auth/profile` | AUTH | `{ first_name?, last_name?, phone?, birth_date? }` | Actualizeaza datele profilului. Returneaza userul actualizat |
| PUT | `/api/auth/password` | AUTH | `{ current_password, new_password }` | Schimba parola (verifica parola curenta, minim 6 caractere noua) |
| PUT | `/api/auth/deactivate` | AUTH | — | Dezactiveaza contul propriu (`is_active = false`) |
| PUT | `/api/auth/profile-image` | AUTH + UPLOAD | `image` (multipart) | Upload imagine de profil. Salvata in `uploads/images/users/{id}/avatar.ext` |
| DELETE | `/api/auth/profile-image` | AUTH | — | Sterge imaginea de profil |

**Raspuns register/login:**
```json
{
  "token": "eyJhbG...",
  "user": { "id": 1, "username": "ion", "email": "ion@ex.com", "role": "user", "first_name": "Ion", "last_name": "Popescu", "profile_image": "/images/users/1/avatar.jpg" }
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

**Raspuns PUT /profile:**
```json
{
  "id": 1, "username": "ion", "first_name": "Ion", "last_name": "Popescu",
  "email": "ion@ex.com", "phone": "+40740000000", "birth_date": "1995-03-15",
  "role": "user", "is_active": true, "profile_image": null, "created_at": "..."
}
```

**Raspuns PUT /password:**
```json
{ "message": "Parola a fost schimbata cu succes." }
```

**Raspuns PUT /deactivate:**
```json
{ "message": "Contul a fost dezactivat." }
```

**Login — cont dezactivat (403):**
```json
{ "error": "Contul este dezactivat. Contactati un administrator." }
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

**Sort permis:** `name_ro`, `name_latin`, `name_en`, `created_at`

---

## 3. Puncte de interes / Observatii (`/api/pois`) — `src/routes/pois.js`

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/pois` | -- | `?plant_id=&user_id=&status=approved&search=&lat=&lng=&radius=10&limit=50&offset=0` | Lista observatii cu filtrare per planta, user, cautare, GPS. Default: doar approved |
| GET | `/api/pois/:id` | -- | — | Detalii observatie cu comentarii si imagini |
| POST | `/api/pois` | AUTH + UPLOAD | vezi mai jos (FormData) | Creeaza observatie noua (status: pending). Trimite notificari |
| PUT | `/api/pois/:id` | AUTH (owner) | `{ comment?, description?, habitat?, ... }` | Editeaza observatia proprie. Reseteaza status la `pending` |
| PUT | `/api/pois/:id/status` | ADMIN | `{ "status": "approved" \| "rejected", "reason?": "..." }` | Aproba/respinge observatie. Trimite notificare autorului |
| DELETE | `/api/pois/:id` | AUTH (owner sau admin) | — | Sterge observatie + imagini + notificari asociate |

**Body POST /api/pois (FormData):**

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|-------------|-----------|
| `plant_id` | int | Da | ID planta |
| `latitude` | decimal | Da | Coordonate GPS |
| `longitude` | decimal | Da | Coordonate GPS |
| `address` | string | Nu | Adresa (se obtine automat prin reverse geocoding daca lipseste) |
| `comment` | string | Nu | Comentariu RO |
| `ai_confidence` | decimal | Nu | Scor AI 0.000–1.000 |
| `image` | file | Nu | Imagine JPG/PNG/WebP |
| `description` | string | Nu | Descriere RO |
| `habitat` | string | Nu | Habitat RO |
| `harvest_period` | string | Nu | Perioada recoltare RO |
| `benefits` | string | Nu | Beneficii RO |
| `contraindications` | string | Nu | Contraindicatii RO |
| `comment_en` | string | Nu | Comentariu EN |
| `description_en` | string | Nu | Descriere EN |
| `habitat_en` | string | Nu | Habitat EN |
| `harvest_period_en` | string | Nu | Perioada recoltare EN |
| `benefits_en` | string | Nu | Beneficii EN |
| `contraindications_en` | string | Nu | Contraindicatii EN |

**Filtrare GPS:** Foloseste formula Haversine. `lat`, `lng` = centrul, `radius` = km.

**Filtrare `?search=`:** Cauta in `name_ro`, `name_latin`, `name_en`, `comment`, `address`.

**Filtrare `?user_id=`:** Returneaza doar observatiile unui utilizator specific (pentru "Plantele mele").

**Notificari la creare POI:**
- `poi_pending` → autorul (confirmare ca e in asteptare)
- `poi_created` → toti adminii (POI nou de moderat)

**Notificari la moderare (PUT /:id/status):**
- `poi_approved` → autorul POI-ului
- `poi_rejected` → autorul POI-ului (include `reason` daca e trimis)

**Notificari la editare (PUT /:id):**
- `poi_edited` → toti adminii (necesita re-moderare)

**Raspuns GET /api/pois:**
```json
{
  "data": [{
    "id": 1, "user_id": 2, "plant_id": 5,
    "latitude": 45.4353, "longitude": 28.008,
    "address": "Str. Brailei 100, Galati",
    "comment": "Gasit langa parc",
    "description": "...", "description_en": "...",
    "habitat": "...", "habitat_en": "...",
    "ai_confidence": 0.940, "status": "approved",
    "plant_name": "Musetel", "name_latin": "...", "plant_name_en": "Chamomile",
    "icon_color": "#4CAF50",
    "author": "ion", "comment_count": 5,
    "primary_image": "/images/poi/1/foto.jpg",
    "images": ["/images/poi/1/foto.jpg"]
  }],
  "total": 16
}
```

**Raspuns GET /api/pois/:id** (include comentarii cu parent_id, user_id, profile_image):
```json
{
  "id": 1, "user_id": 2, "plant_id": 5,
  "latitude": 45.4353, "longitude": 28.008,
  "comment": "Gasit langa parc",
  "description": "...", "description_en": "...",
  "comment_count": 5,
  "images": ["/images/poi/1/foto1.jpg", "/images/poi/1/foto2.jpg"],
  "primary_image": "/images/poi/1/foto1.jpg",
  "comments": [{
    "id": 1, "user_id": 3, "content": "Frumos!", "username": "maria",
    "profile_image": "/images/users/3/avatar.jpg", "parent_id": null, "created_at": "..."
  }]
}
```

**Body PUT /api/pois/:id/status (reject cu motiv):**
```json
{
  "status": "rejected",
  "reason": "Imaginea nu este clara, nu se poate identifica planta."
}
```

---

## 4. Comentarii (`/api/comments`) — `src/routes/comments.js`

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/pois/:poiId/comments` | -- | `?page=1&limit=20` | Lista comentarii pe o observatie (paginat, ASC) |
| POST | `/api/pois/:poiId/comments` | AUTH | `{ "content": "...", "parent_id?": 5 }` | Adauga comentariu (cu reply optional). Trimite notificare autorului POI-ului |
| DELETE | `/api/comments/:id` | AUTH (owner sau admin) | — | Sterge comentariu (CASCADE pe reply-uri) |

**Body POST (reply):**
```json
{
  "content": "Raspunsul meu la comentariu",
  "parent_id": 5
}
```

**Raspuns GET:**
```json
{
  "data": [
    { "id": 1, "user_id": 3, "content": "...", "username": "ion", "profile_image": "/images/users/3/avatar.jpg", "parent_id": null, "created_at": "..." },
    { "id": 2, "user_id": 4, "content": "Raspuns...", "username": "maria", "profile_image": null, "parent_id": 1, "created_at": "..." }
  ],
  "total": 5,
  "page": 1
}
```

**Notificare la comentariu nou:**
- `poi_commented` → autorul POI-ului (doar daca nu e el cel care comenteaza)

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
| GET | `/api/admin/users` | `?search=&role=user\|admin` | Lista utilizatori cu cautare (username, email, first_name, last_name) si filtru rol |
| PUT | `/api/admin/users/:id` | `{ "role?": "admin", "is_active?": false }` | Schimba rol si/sau activare cont |
| DELETE | `/api/admin/users/:id` | — | Sterge utilizator (nu pe sine) |

### Moderare POI

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/admin/pois/pending` | Lista observatii in asteptare (pending) |

### Statistici

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/admin/stats` | Dashboard: totalUsers, activeUsers, totalPlants, totalPois, approvedPois, pendingPois, rejectedPois, totalComments |

**Raspuns /api/admin/stats:**
```json
{
  "totalUsers": 5,
  "activeUsers": 4,
  "totalPlants": 19,
  "totalPois": 16,
  "approvedPois": 10,
  "pendingPois": 3,
  "rejectedPois": 3,
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

## 8. Notificari (`/api/notifications`) — `src/routes/notifications.js`

| Metoda | Ruta | Acces | Query | Descriere |
|--------|------|-------|-------|-----------|
| GET | `/api/notifications` | AUTH | `?limit=50` | Lista notificari ale userului autentificat (DESC dupa created_at) |
| GET | `/api/notifications/unread-count` | AUTH | — | Numarul de notificari necitite |
| PUT | `/api/notifications/:id/read` | AUTH | — | Marcheaza o notificare ca citita (doar a userului propriu) |
| PUT | `/api/notifications/read-all` | AUTH | — | Marcheaza TOATE notificarile userului ca citite |

**Raspuns GET /api/notifications:**
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 2,
      "type": "poi_approved",
      "title": "Observatie aprobata",
      "message": "Observatia ta pentru Musetel a fost aprobata.",
      "is_read": false,
      "poi_id": 15,
      "plant_name": "Musetel",
      "reason": null,
      "created_at": "2026-03-25T14:30:00Z"
    }
  ],
  "total": 12,
  "unread_count": 3
}
```

**Raspuns GET /api/notifications/unread-count:**
```json
{ "unread_count": 3 }
```

**Tipuri de notificari (create automat):**

| Tip | Cand | Cine primeste | Trigger |
|-----|------|---------------|---------|
| `poi_created` | POST `/api/pois` | Toti adminii | pois.js |
| `poi_pending` | POST `/api/pois` | Autorul POI-ului | pois.js |
| `poi_approved` | PUT `/api/pois/:id/status` approved | Autorul POI-ului | pois.js |
| `poi_rejected` | PUT `/api/pois/:id/status` rejected | Autorul POI-ului (include reason) | pois.js |
| `poi_edited` | PUT `/api/pois/:id` | Toti adminii | pois.js |
| `poi_commented` | POST `/api/pois/:poiId/comments` | Autorul POI-ului (daca nu e el) | comments.js |

---

## 9. Favorite (`/api/favorites`) — `src/routes/favorites.js`

Favorite pe **plante** (nu pe POI-uri). Persistente pe server.

| Metoda | Ruta | Acces | Descriere |
|--------|------|-------|-----------|
| GET | `/api/favorites` | AUTH | Lista `plant_id`-uri favorite ale userului |
| POST | `/api/favorites/:plantId` | AUTH | Adauga planta la favorite |
| DELETE | `/api/favorites/:plantId` | AUTH | Sterge planta din favorite |

**Raspuns GET /api/favorites:**
```json
{ "data": [1, 3, 5] }
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
| 403 | Lipsa permisiuni (nu e admin / nu e owner / cont dezactivat) |
| 404 | Resursa negasita |
| 409 | Username/email deja exista |
| 413 | Fisier prea mare (>10MB) |
| 500 | Eroare server |
| 503 | Ollama indisponibil (doar `/api/chat`) |

---

## Rate Limiting

- **1000 requesturi** per IP la fiecare **15 minute** pe toate rutele `/api/*`

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
    ├── auth.js            # /api/auth      (register, login, me, profile, password, deactivate)
    ├── plants.js          # /api/plants    (CRUD, search, sort)
    ├── pois.js            # /api/pois      (CRUD, edit, GPS filter, moderare, notificari)
    ├── comments.js        # /api/comments  (CRUD cu reply-uri, notificari)
    ├── ai.js              # /api/identify  + /api/chat
    ├── admin.js           # /api/admin     (users, stats, config, model)
    ├── config.js          # /api/config    (setari harta publice)
    ├── notifications.js   # /api/notifications (lista, unread-count, mark read)
    ├── favorites.js       # /api/favorites (CRUD favorite pe plante)
    └── users.js           # /api/users     (profil public, istoric)
```
