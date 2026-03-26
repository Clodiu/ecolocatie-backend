# Backend TODO — Endpointuri necesare pentru frontend

Frontend-ul apeleaza aceste endpointuri care **nu exista inca** in backend sau necesita modificari. Fiecare sectiune contine endpoint-ul, metoda HTTP, body/query, ce trebuie sa faca si ce returneaza.

---

## 1. Notificari (`/api/notifications`) — MODUL NOU

Trebuie creat fisierul `src/routes/notifications.js` si tabelul `notifications` in MySQL.

### Tabel MySQL necesar:

```sql
CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('poi_created', 'poi_approved', 'poi_rejected', 'poi_pending', 'poi_edited', 'poi_commented') NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  poi_id INT NULL,
  plant_name VARCHAR(255) NULL,
  reason VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (poi_id) REFERENCES pois(id) ON DELETE SET NULL
);
```

### Endpointuri:

| Metoda | Ruta | Acces | Query / Body | Descriere |
|--------|------|-------|--------------|-----------|
| GET | `/api/notifications` | AUTH | `?limit=50` | Lista notificari ale userului autentificat (ordonate descrescator dupa created_at) |
| GET | `/api/notifications/unread-count` | AUTH | — | Returneaza doar numarul de notificari necitite |
| PUT | `/api/notifications/:id/read` | AUTH | — | Marcheaza o notificare ca citita (doar a userului propriu) |
| PUT | `/api/notifications/read-all` | AUTH | — | Marcheaza TOATE notificarile userului ca citite |

**Raspuns GET `/api/notifications`:**
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

**Raspuns GET `/api/notifications/unread-count`:**
```json
{
  "unread_count": 3
}
```

### Cand se creeaza notificari (trigger-e in alte rute):

| Eveniment | Cine primeste | type | Unde se face trigger-ul |
|-----------|---------------|------|------------------------|
| POST `/api/pois` (observatie noua) | Toti adminii | `poi_created` | `src/routes/pois.js` - dupa creare POI |
| PUT `/api/pois/:id/status` cu `approved` | Autorul POI-ului | `poi_approved` | `src/routes/pois.js` - dupa moderare |
| PUT `/api/pois/:id/status` cu `rejected` | Autorul POI-ului | `poi_rejected` | `src/routes/pois.js` - dupa moderare (include `reason` din body) |
| POST `/api/pois` (dupa creare) | Autorul POI-ului | `poi_pending` | `src/routes/pois.js` - confirmare ca e in asteptare |
| POST `/api/comments/:poiId` | Autorul POI-ului (daca nu e el cel care comenteaza) | `poi_commented` | `src/routes/comments.js` - dupa adaugare comentariu |

**Exemplu trigger in `pois.js` dupa moderare:**
```javascript
// Dupa UPDATE status
const poiOwner = await db.query('SELECT user_id, plant_id FROM pois WHERE id = ?', [poiId]);
const plantName = await db.query('SELECT name_ro FROM plants WHERE id = ?', [poiOwner.plant_id]);

await db.query(
  'INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name, reason) VALUES (?, ?, ?, ?, ?, ?, ?)',
  [poiOwner.user_id, status === 'approved' ? 'poi_approved' : 'poi_rejected', ..., reason]
);
```

---

## 2. Comentarii — Modificari necesare

### 2.1 Suport `parent_id` pentru reply-uri

Frontend-ul trimite `parent_id` optional in body-ul POST. Trebuie adaugat in tabelul `comments`:

```sql
ALTER TABLE comments ADD COLUMN parent_id INT NULL;
ALTER TABLE comments ADD FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE;
```

**POST `/api/comments/:poiId`** — body modificat:
```json
{
  "content": "Raspunsul meu",
  "parent_id": 5
}
```

**GET `/api/comments/poi/:poiId`** — raspunsul trebuie sa includa `parent_id`:
```json
{
  "data": [
    { "id": 1, "content": "...", "username": "ion", "parent_id": null, "created_at": "..." },
    { "id": 2, "content": "Raspuns...", "username": "maria", "parent_id": 1, "created_at": "..." }
  ],
  "total": 5,
  "page": 1
}
```

### 2.2 `comment_count` in raspunsul POI

GET `/api/pois` si GET `/api/pois/:id` trebuie sa includa numarul de comentarii:

```sql
SELECT p.*, (SELECT COUNT(*) FROM comments WHERE poi_id = p.id) AS comment_count FROM pois p ...
```

Raspuns:
```json
{
  "data": [
    { "id": 1, "...", "comment_count": 5 }
  ]
}
```

### 2.3 Trigger notificare la comentariu nou

In `src/routes/comments.js`, dupa INSERT comentariu:
```javascript
// Gaseste autorul POI-ului
const poi = await db.query('SELECT user_id, plant_id FROM pois WHERE id = ?', [poiId]);
const commenterUserId = req.user.id; // din JWT

// Notifica autorul POI-ului (doar daca nu e el insusi)
if (poi.user_id !== commenterUserId) {
  const plantName = await db.query('SELECT name_ro FROM plants WHERE id = ?', [poi.plant_id]);
  await db.query(
    'INSERT INTO notifications (user_id, type, title, message, poi_id, plant_name) VALUES (?, "poi_commented", ?, ?, ?, ?)',
    [poi.user_id, "Comentariu nou", `${req.user.username} a comentat...`, poiId, plantName]
  );
}
```

---

## 3. Observatii (POIs) — Modificari necesare

### 3.1 Campuri noi la creare POI

POST `/api/pois` trebuie sa accepte campuri aditionale in FormData:

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|-------------|-----------|
| `description` | string | Da | Descriere RO |
| `habitat` | string | Da | Habitat RO |
| `harvest_period` | string | Da | Perioada recoltare RO |
| `benefits` | string | Da | Beneficii RO |
| `contraindications` | string | Da | Contraindicatii RO |
| `comment` | string | Da | Comentariu RO |
| `description_en` | string | Da | Descriere EN |
| `habitat_en` | string | Da | Habitat EN |
| `harvest_period_en` | string | Da | Perioada recoltare EN |
| `benefits_en` | string | Da | Beneficii EN |
| `contraindications_en` | string | Da | Contraindicatii EN |
| `comment_en` | string | Da | Comentariu EN |

Daca tabelul `pois` nu are aceste coloane, trebuie adaugate:
```sql
ALTER TABLE pois ADD COLUMN description TEXT NULL;
ALTER TABLE pois ADD COLUMN habitat TEXT NULL;
ALTER TABLE pois ADD COLUMN harvest_period VARCHAR(255) NULL;
ALTER TABLE pois ADD COLUMN benefits TEXT NULL;
ALTER TABLE pois ADD COLUMN contraindications TEXT NULL;
ALTER TABLE pois ADD COLUMN description_en TEXT NULL;
ALTER TABLE pois ADD COLUMN habitat_en TEXT NULL;
ALTER TABLE pois ADD COLUMN harvest_period_en VARCHAR(255) NULL;
ALTER TABLE pois ADD COLUMN benefits_en TEXT NULL;
ALTER TABLE pois ADD COLUMN contraindications_en TEXT NULL;
ALTER TABLE pois ADD COLUMN comment_en TEXT NULL;
```

### 3.2 GET `/api/pois` si GET `/api/pois/:id` — returnare campuri EN

Raspunsul trebuie sa includa si campurile in engleza:
```json
{
  "id": 1,
  "description": "Text RO...",
  "description_en": "Text EN...",
  "habitat": "...",
  "habitat_en": "...",
  "comment_count": 3
}
```

### 3.3 PUT `/api/pois/:id/status` — suport `reason` la reject

Body:
```json
{
  "status": "rejected",
  "reason": "Imaginea nu este clara, nu se poate identifica planta."
}
```
Campul `reason` trebuie stocat in notificarea creata (nu in POI).

---

## 4. Autentificare — Modificari necesare

### 4.1 PUT `/api/auth/profile` — Actualizare profil

Frontend-ul trimite update-uri de profil dar nu exista endpoint dedicat. Trebuie creat:

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| PUT | `/api/auth/profile` | AUTH | `{ "first_name?", "last_name?", "phone?", "birth_date?" }` | Actualizeaza datele profilului |

**Raspuns:**
```json
{
  "id": 1,
  "username": "tudor",
  "email": "tb173@student.ugal.ro",
  "first_name": "Tudor",
  "last_name": "Baranga",
  "phone": "+40712345678",
  "birth_date": "2000-05-15",
  "role": "user",
  "is_active": true,
  "profile_image": "/uploads/avatars/1.jpg"
}
```

### 4.2 PUT `/api/auth/password` — Schimbare parola

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| PUT | `/api/auth/password` | AUTH | `{ "current_password", "new_password" }` | Schimba parola (verifica parola curenta) |

Validari:
- `current_password` obligatoriu, verificat cu bcrypt
- `new_password` minim 6 caractere
- Returneaza 400 daca parola curenta e gresita

### 4.3 PUT `/api/auth/deactivate` — Dezactivare cont

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| PUT | `/api/auth/deactivate` | AUTH | — | Seteaza `is_active = false` pe contul propriu |

Dupa dezactivare, userul nu se mai poate loga (verificare `is_active` la login).

---

## 5. Favorite — Mutare pe backend (optional, acum e local)

Favorurile sunt stocate in AsyncStorage pe telefon. Daca vrei persistenta pe server:

```sql
CREATE TABLE favorites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  poi_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_fav (user_id, poi_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (poi_id) REFERENCES pois(id) ON DELETE CASCADE
);
```

| Metoda | Ruta | Acces | Descriere |
|--------|------|-------|-----------|
| GET | `/api/favorites` | AUTH | Lista favorite ale userului |
| POST | `/api/favorites/:poiId` | AUTH | Adauga la favorite |
| DELETE | `/api/favorites/:poiId` | AUTH | Sterge din favorite |

---

## 6. Cautare server-side (optimization)

Frontend-ul descarca TOATE plantele si POI-urile si filtreaza local. Pe masura ce cresc datele, trebuie mutat pe backend:

### 6.1 Cautare plante (deja partial exista `?search=`)

Backend-ul are deja `GET /api/plants?search=musetel` dar frontend-ul nu-l foloseste. Trebuie verificat ca functioneaza corect cu diacritice si cautare partiala.

### 6.2 Cautare POI-uri pe harta

| Metoda | Ruta | Acces | Query | Descriere |
|--------|------|-------|-------|-----------|
| GET | `/api/pois` | -- | `?search=musetel` | Cautare POI dupa numele plantei, comentariu, adresa |

### 6.3 Cautare utilizatori admin (deja exista `?search=`)

Backend-ul are `GET /api/admin/users?search=`. Trebuie verificat ca returneaza si `first_name`, `last_name`.

---

## 7. Statistici admin — Camp lipsa

GET `/api/admin/stats` trebuie sa returneze si:
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

Campuri noi necesare: `activeUsers`, `approvedPois`, `rejectedPois` (frontend-ul le calculeaza acum local, dar ar fi mai eficient din backend).

---

## 8. Stergere observatie

DELETE `/api/pois/:id` exista in ROUTES.md dar frontend-ul nu il foloseste inca. Backend-ul trebuie sa:
- Verifice ca userul e owner SAU admin
- Stearga imaginile asociate de pe disc
- Stearga comentariile asociate (CASCADE)
- Stearga notificarile asociate (CASCADE)

---

## 9. Comentarii — Campuri suplimentare in raspuns

GET `/api/comments/poi/:poiId` trebuie sa returneze si `user_id` si `profile_image` pentru fiecare comentariu (frontend-ul le foloseste pentru permisiuni de stergere si avatar):

```json
{
  "data": [
    {
      "id": 1,
      "user_id": 3,
      "content": "...",
      "username": "claudiu_craciun",
      "profile_image": "/uploads/avatars/3.jpg",
      "parent_id": null,
      "created_at": "..."
    }
  ],
  "total": 5,
  "page": 1
}
```

SQL:
```sql
SELECT c.id, c.user_id, c.poi_id, c.content, c.parent_id, c.created_at,
       u.username, u.profile_image
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.poi_id = ?
ORDER BY c.created_at ASC
LIMIT ? OFFSET ?
```

---

## 10. Observatii — Trimitere campuri noi la creare POI

`saveSighting()` din frontend trimite acum toate campurile prin FormData. Backend-ul trebuie sa le accepte si sa le salveze:

**Campuri trimise in POST `/api/pois` (FormData):**

| Camp | Trimis acum? | Observatii |
|------|-------------|------------|
| `plant_id` | Da | Exista deja |
| `latitude` | Da | Exista deja |
| `longitude` | Da | Exista deja |
| `comment` | Da | Exista deja |
| `image` | Da | Exista deja |
| `ai_confidence` | Da | Exista deja |
| `description` | **NU inca** | Trebuie adaugat in frontend + backend |
| `habitat` | **NU inca** | Trebuie adaugat in frontend + backend |
| `harvest_period` | **NU inca** | Trebuie adaugat in frontend + backend |
| `benefits` | **NU inca** | Trebuie adaugat in frontend + backend |
| `contraindications` | **NU inca** | Trebuie adaugat in frontend + backend |
| `description_en` | **NU inca** | Trebuie adaugat in frontend + backend |
| `habitat_en` | **NU inca** | Trebuie adaugat in frontend + backend |
| `harvest_period_en` | **NU inca** | Trebuie adaugat in frontend + backend |
| `benefits_en` | **NU inca** | Trebuie adaugat in frontend + backend |
| `contraindications_en` | **NU inca** | Trebuie adaugat in frontend + backend |
| `comment_en` | **NU inca** | Trebuie adaugat in frontend + backend |

**NOTA:** Frontend-ul colecteaza deja aceste campuri in pasul 4 (CreatePOIForm), dar `sightingsRepository.ts` nu le trimite inca toate prin FormData. Cand backend-ul e gata sa le primeasca, se adauga si in frontend.

---

## 11. Observatii per utilizator — Endpoint dedicat

Frontend-ul (modulul "Plantele mele") descarca TOATE POI-urile si filtreaza local per `user_id`. Pe masura ce cresc datele, trebuie un endpoint dedicat:

| Metoda | Ruta | Acces | Query | Descriere |
|--------|------|-------|-------|-----------|
| GET | `/api/pois/user/:userId` | AUTH | `?status=&limit=50&offset=0` | POI-urile unui utilizator specific |

SAU alternativ, query param pe endpoint-ul existent:

| Metoda | Ruta | Acces | Query | Descriere |
|--------|------|-------|-------|-----------|
| GET | `/api/pois` | -- | `?user_id=2&limit=50` | Filtreaza POI-uri per utilizator |

Raspunsul trebuie sa includa toate campurile POI + `comment_count`.

---

## 12. Editare observatie — Endpoint nou

Frontend-ul are tipul de notificare `poi_edited` dar nu exista inca endpoint de editare POI. Trebuie creat:

| Metoda | Ruta | Acces | Body | Descriere |
|--------|------|-------|------|-----------|
| PUT | `/api/pois/:id` | AUTH (owner) | `{ description?, habitat?, comment?, ... }` | Editeaza observatia proprie |

Comportament:
- Doar owner-ul poate edita
- Dupa editare, status-ul revine la `pending` (necesita re-moderare)
- Se creeaza notificare `poi_edited` pentru toti adminii
- Campurile editabile: `comment`, `description`, `habitat`, `harvest_period`, `benefits`, `contraindications` + variantele `_en`

---

## 13. Favorite pe plante (nu pe POI-uri)

Frontend-ul foloseste favorite per `plant_id` (nu per `poi_id`). Tabelul si endpoint-urile trebuie adaptate:

```sql
CREATE TABLE favorites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  plant_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_fav (user_id, plant_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
);
```

| Metoda | Ruta | Acces | Descriere |
|--------|------|-------|-----------|
| GET | `/api/favorites` | AUTH | Lista `plant_id`-uri favorite ale userului |
| POST | `/api/favorites/:plantId` | AUTH | Adauga planta la favorite |
| DELETE | `/api/favorites/:plantId` | AUTH | Sterge planta din favorite |

**Raspuns GET:**
```json
{
  "data": [1, 3, 5]
}
```

---

## Prioritati de implementare

1. **URGENT** — Notificari (modul complet nou, frontend-ul polling-uieste la 30s)
2. **URGENT** — `comment_count` in raspunsul POI-urilor
3. **URGENT** — `parent_id` pe comentarii (reply-uri)
4. **URGENT** — `user_id` + `profile_image` in raspunsul comentariilor
5. **IMPORTANT** — Campuri EN pe POI-uri (coloane noi + accept in POST)
6. **IMPORTANT** — Trigger-e notificari la creare/moderare POI si la comentariu
7. **IMPORTANT** — PUT `/api/auth/profile` si PUT `/api/auth/password`
8. **IMPORTANT** — GET `/api/pois?user_id=X` (observatii per utilizator)
9. **MEDIU** — Reason la reject POI
10. **MEDIU** — PUT `/api/auth/deactivate`
11. **MEDIU** — PUT `/api/pois/:id` (editare observatie + re-moderare)
12. **LOW** — Favorite pe plante (`/api/favorites`)
13. **LOW** — Cautare server-side (functioneaza local deocamdata)
