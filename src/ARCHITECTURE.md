# EcoLocatie Backend — Arhitectura `src/`

## Structura folderului

```
src/
├── server.js                  # Entry point — Express app
├── ngrok.js                   # Utilitar — tunel public ngrok
├── config/
│   └── db.js                 1 # Conexiune MySQL (pool)
├── middleware/
│   ├── auth.js                # JWT autentificare + rol admin
│   └── upload.js              # Multer — upload imagini
└── routes/
    ├── admin.js               # Panou admin (useri, moderare, statistici, config, model AI)
    ├── ai.js                  # Identificare plante + chatbot RAG
    ├── auth.js                # Register, login, profil, parola, avatar
    ├── comments.js            # Comentarii pe observatii (cu reply-uri)
    ├── config.js              # Configurare harta (public)
    ├── favorites.js           # Plante favorite per utilizator
    ├── notifications.js       # Notificari in-app
    ├── plants.js              # CRUD plante medicinale
    ├── pois.js                # CRUD observatii pe harta (Points of Interest)
    └── users.js               # Istoric activitate utilizator
```

---

## Entry point

### `server.js`

Configureaza aplicatia Express cu:
- **CORS** — acces cross-origin
- **Helmet** — headere de securitate
- **Morgan** — logging cereri HTTP
- **Rate limiting** — max 1000 cereri / 15 min per IP
- **Static files** — serveste `/uploads` si `/images`
- **Montare rute** — toate rutele sub `/api/`
- **Error handling** — 413 (fisier prea mare), 400 (imagine invalida), 500 (erori generale)

### `ngrok.js`

Utilitar de dezvoltare. Porneste serverul Express si creeaza un tunel public ngrok catre `localhost:3000`. Foloseste authtoken din `.env`.

---

## Config

### `config/db.js`

Pool MySQL cu `mysql2/promise`:
- **Pool size:** 10 conexiuni
- **Charset:** utf8mb4 (suport diacritice + emoji)
- **Variabile de mediu:** `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- Testeaza conexiunea la pornire

---

## Middleware

### `middleware/auth.js`

Doua functii exportate:

| Functie | Scop |
|---------|------|
| `auth(req, res, next)` | Verifica JWT din header `Authorization: Bearer <token>`. Ataseaza `req.user` (id, username, role). Returneaza 401 daca lipseste/invalid |
| `adminOnly(req, res, next)` | Verifica `req.user.role === 'admin'`. Returneaza 403 daca nu e admin |

### `middleware/upload.js`

Configurare Multer:
- **Tipuri acceptate:** JPG, PNG, WebP
- **Dimensiune maxima:** 10 MB (configurabil via `MAX_FILE_SIZE`)
- **Destinatie:** `uploads/images/` (configurabil via `UPLOAD_DIR`)
- **Nume fisier:** `[timestamp]-[random].ext`

---

## Rute

### `routes/auth.js` — Autentificare si profil

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| POST | `/api/auth/register` | — | Inregistrare cont (username, email, parola, date optionale, avatar) |
| POST | `/api/auth/login` | — | Login cu email + parola. Verifica `is_active` |
| GET | `/api/auth/me` | ✓ | Profilul utilizatorului curent |
| PUT | `/api/auth/profile` | ✓ | Actualizeaza first_name, last_name, phone, birth_date |
| PUT | `/api/auth/password` | ✓ | Schimba parola (verifica parola curenta, min 6 caractere) |
| PUT | `/api/auth/deactivate` | ✓ | Dezactiveaza contul propriu |
| PUT | `/api/auth/profile-image` | ✓ | Upload/inlocuire avatar |
| DELETE | `/api/auth/profile-image` | ✓ | Sterge avatarul |

**Stocare avatar:** `/images/users/{userId}/avatar{ext}`

---

### `routes/plants.js` — Plante medicinale

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/plants` | — | Lista plante cu cautare, sortare, paginare, localizare (ro/en) |
| GET | `/api/plants/:id` | — | Detalii planta cu beneficii, contraindicatii, parti utilizabile, imagini |
| POST | `/api/plants` | Admin | Creeaza planta + beneficii/contraindicatii/parti |
| PUT | `/api/plants/:id` | Admin | Actualizeaza planta (sterge si reinseaza tabelele relationate) |
| DELETE | `/api/plants/:id` | Admin | Sterge planta |

**Query params GET:** `search`, `sort` (name_ro/name_latin/name_en/created_at), `order` (ASC/DESC), `limit`, `offset`, `lang` (ro/en)

**Logica imagini:** citeste fisierele de pe disc din folderul `image_url`, returneaza `primary_image` + `images[]`

---

### `routes/pois.js` — Observatii pe harta

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/pois` | — | Lista observatii cu filtrare avansata (planta, user, status, cautare, geolocatie) |
| GET | `/api/pois/:id` | — | Detalii observatie + comentarii + planta + imagini |
| POST | `/api/pois` | ✓ | Creeaza observatie (upload imagine, geocoding invers Nominatim) |
| PUT | `/api/pois/:id` | ✓ (autor) | Editeaza observatia (reseteaza status la pending) |
| PUT | `/api/pois/:id/status` | Admin | Aproba/respinge observatia (cu motiv optional) |
| DELETE | `/api/pois/:id` | ✓ (autor/admin) | Sterge observatia + imagini de pe disc + notificari |

**Filtrare geografica:** formula Haversine pentru cautare in raza (km) — params: `lat`, `lng`, `radius`

**Flow moderare:** `pending` → `approved` / `rejected`. Pe harta apar doar cele `approved`.

**Notificari declansate:**
- Creare → notifica toti adminii (`poi_created`) + autorul (`poi_pending`)
- Editare → notifica toti adminii (`poi_edited`), status revine la `pending`
- Aprobare/respingere → notifica autorul (`poi_approved` / `poi_rejected`)

---

### `routes/comments.js` — Comentarii

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/pois/:poiId/comments` | — | Lista comentarii paginata (include username, profile_image) |
| POST | `/api/pois/:poiId/comments` | ✓ | Adauga comentariu (suport `parent_id` pentru reply-uri) |
| DELETE | `/api/comments/:id` | ✓ (autor/admin) | Sterge comentariu |

**Notificari:** la comentariu nou, autorul POI-ului primeste notificare (daca nu e el insusi cel care comenteaza)

---

### `routes/notifications.js` — Notificari

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/notifications` | ✓ | Lista notificari (limit configurabil, default 50) |
| GET | `/api/notifications/unread-count` | ✓ | Numarul de notificari necitite |
| PUT | `/api/notifications/:id/read` | ✓ | Marcheaza o notificare ca citita |
| PUT | `/api/notifications/read-all` | ✓ | Marcheaza toate ca citite |

---

### `routes/favorites.js` — Plante favorite

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/favorites` | ✓ | Lista plant_id-uri favorite |
| POST | `/api/favorites/:plantId` | ✓ | Adauga planta la favorite |
| DELETE | `/api/favorites/:plantId` | ✓ | Sterge din favorite |

---

### `routes/ai.js` — Servicii AI

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| POST | `/api/identify` | — | Identificare planta din imagine (ruleaza `python/classify.py`) |
| POST | `/api/chat` | — | Chatbot RAG despre fitoterapie (Ollama gemma3:1b) |
| GET | `/api/chat/status` | — | Status coada chatbot (busy, queue_length) |

**Identificare:** executa scriptul Python cu modelul activ din `config.active_model`, cauta planta in DB dupa `folder_name`, returneaza detalii + scor confidenta.

**Chatbot RAG:**
1. Elimina diacritice + stemming romanesc
2. Cauta plante relevante in DB (beneficii, nume, descrieri)
3. Construieste context cu max 3 plante
4. Trimite la Ollama cu system prompt (detectie automata limba ro/en)
5. Salveaza in `chat_history`
6. Coada seriala — max 1 cerere concurenta

**Warmup:** la pornirea serverului, pre-incarca modelul gemma3:1b (timeout 60s)

---

### `routes/admin.js` — Panou admin

Toate rutele necesita `auth` + `adminOnly`.

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/admin/users` | Lista useri cu cautare si filtrare rol |
| PUT | `/api/admin/users/:id` | Schimba rol sau is_active |
| DELETE | `/api/admin/users/:id` | Sterge user (nu se poate sterge pe sine) |
| GET | `/api/admin/pois/pending` | Lista observatii in asteptare |
| GET | `/api/admin/stats` | Statistici: useri, plante, POI-uri (total/approved/pending/rejected), comentarii |
| GET | `/api/admin/config` | Configurare harta |
| PUT | `/api/admin/config` | Actualizeaza setari harta |
| GET | `/api/admin/model` | Model AI activ + lista modele disponibile |
| PUT | `/api/admin/model` | Schimba modelul AI activ |

---

### `routes/config.js` — Configurare publica

| Metoda | Ruta | Auth | Descriere |
|--------|------|:----:|-----------|
| GET | `/api/config/map` | — | Setari harta: centru, zoom, tile URL, bounds |

---

### `routes/users.js` — Istoric utilizator

Toate rutele necesita `auth`.

| Metoda | Ruta | Descriere |
|--------|------|-----------|
| GET | `/api/users/:id/plants` | Plantele observate de user (grupate, cu numar observatii) |
| GET | `/api/users/:id/history` | Toate observatiile userului (paginat) |
| DELETE | `/api/users/:id/plants/:plantId` | Sterge toate observatiile unui user pentru o planta |

---

## Aspecte transversale

**Stocare imagini:**
- Avatare: `/images/users/{userId}/avatar{ext}`
- Plante: referinta folder in `plants.image_url`
- Observatii: `/images/poi/{poiId}/{filename}`

**Multilingv:** campuri `_en` pe plante si observatii, param `lang` pe endpointuri

**Securitate:** JWT, bcrypt, role-based access (user/admin), rate limiting, Helmet

**Notificari automate:** create la evenimentele de creare/editare/moderare POI si la comentarii noi