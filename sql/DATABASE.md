# EcoLocatie — Documentatia bazei de date

**Versiune:** 3.0
**Proiect:** Concurs Severin Bumbaru 2026
**Motor:** MySQL 8+ cu `utf8mb4_romanian_ci`

---

## Prezentare generala

Baza de date sustine o aplicatie de cartografiere a plantelor medicinale din zona Galati. Utilizatorii pot adauga observatii (sighting-uri) geolocalizate, identifica plante cu ajutorul AI-ului, consulta un chatbot RAG despre fitoterapie si interactiona prin comentarii.

### Diagrama relatiilor

```
users 1──N points_of_interest N──1 plants
  │                │                  │
  │                │    [poze: disc]  ├── N plant_benefits
  │                │    /images/poi/  ├── N plant_contraindications
  │                └── N comments     └── N plant_usable_parts
  │                         │
  └─────────────────────────┘

users 1──N chat_history
users 1──N notifications ──N points_of_interest
users 1──N favorites N──1 plants

config (singleton — setari harta)
```

---

## Tabele

### 1. `users`

Utilizatorii aplicatiei. Suporta doua roluri: `admin` si `user`.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | Identificator unic |
| `username` | VARCHAR(50), UNIQUE | ✓ | Numele de utilizator |
| `first_name` | VARCHAR(50) | — | Prenumele |
| `last_name` | VARCHAR(50) | — | Numele de familie |
| `email` | VARCHAR(100), UNIQUE | ✓ | Email, folosit la login |
| `password_hash` | VARCHAR(255) | ✓ | Hash bcrypt/argon2 |
| `phone` | VARCHAR(20) | — | Telefon |
| `birth_date` | DATE | — | Data nasterii |
| `role` | ENUM('user','admin') | ✓ | Default: `user` |
| `is_active` | BOOLEAN | ✓ | Default: `TRUE`. Admin poate dezactiva conturi |
| `profile_image` | VARCHAR(255) | — | URL avatar |
| `created_at` | DATETIME | ✓ | Auto-generat |

---

### 2. `plants`

Catalogul de plante medicinale (19 inregistrari in seed).

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | Identificator unic |
| `name_ro` | VARCHAR(100) | ✓ | Numele in romana |
| `name_latin` | VARCHAR(100) | — | Numele stiintific |
| `name_en` | VARCHAR(100) | — | Numele in engleza |
| `family` | VARCHAR(100) | — | Familia botanica (ex: Asteraceae, Lamiaceae) |
| `description` | TEXT | — | Descriere detaliata (RO) |
| `description_en` | TEXT | — | Descriere detaliata (EN) |
| `habitat` | TEXT | — | Unde creste planta in natura (RO) |
| `habitat_en` | TEXT | — | Habitat (EN) |
| `harvest_period` | VARCHAR(150) | — | Perioada de recoltare (RO) |
| `harvest_period_en` | VARCHAR(150) | — | Harvest period (EN) |
| `preparation` | TEXT | — | Mod de preparare si utilizare (RO) |
| `preparation_en` | TEXT | — | Preparation method (EN) |
| `image_url` | VARCHAR(255) | — | Calea spre folderul cu poze (ex: `/images/plants/musetel`). API-ul citeste fisierele de pe disc |
| `icon_color` | VARCHAR(7) | — | Cod hex culoare marker pe harta. Default: `#4CAF50` |
| `folder_name` | VARCHAR(100) | ✓ | Numele folderului din datasetul AI |
| `created_at` | DATETIME | ✓ | Auto-generat |

**Logica imagini:** `image_url` stocheaza calea spre folder (ex: `/images/plants/musetel`), nu un fisier specific. API-ul citeste fisierele de pe disc si returneaza:
- `primary_image` — primul fisier din folder (sortat alfabetic), folosit in liste
- `images[]` — toate fisierele din folder, folosit in pagina de detalii/galerie

---

### 3. `plant_usable_parts`

Partile utilizabile ale fiecarei plante, normalizat.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `part` | VARCHAR(100) | ✓ | Ex: „frunze", „radacina", „florile" (RO) |
| `part_en` | VARCHAR(100) | — | English translation |

---

### 4. `plant_benefits`

Beneficii medicinale (4-5 per planta).

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `benefit` | VARCHAR(255) | ✓ | Un beneficiu medical (RO) |
| `benefit_en` | VARCHAR(255) | — | English translation |

---

### 5. `plant_contraindications`

Contraindicatii (2-4 per planta).

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `contraindication` | VARCHAR(255) | ✓ | O contraindicatie (RO) |
| `contraindication_en` | VARCHAR(255) | — | English translation |

---

### 6. `points_of_interest`

Observatiile (sighting-urile) de plante pe harta.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | Cine a creat observatia |
| `plant_id` | INT, FK → plants.id | ✓ | Planta identificata |
| `latitude` | DECIMAL(10,7) | ✓ | Coordonate GPS |
| `longitude` | DECIMAL(10,7) | ✓ | Coordonate GPS |
| `address` | VARCHAR(255) | — | Adresa (geocoding invers) |
| `comment` | TEXT | — | Comentariu la observatie (RO) |
| `comment_en` | TEXT | — | Comentariu (EN) |
| `description` | TEXT | — | Descriere observatie (RO) |
| `description_en` | TEXT | — | Descriere observatie (EN) |
| `habitat` | TEXT | — | Habitat observat (RO) |
| `habitat_en` | TEXT | — | Habitat observat (EN) |
| `harvest_period` | VARCHAR(255) | — | Perioada recoltare (RO) |
| `harvest_period_en` | VARCHAR(255) | — | Perioada recoltare (EN) |
| `benefits` | TEXT | — | Beneficii (RO) |
| `benefits_en` | TEXT | — | Beneficii (EN) |
| `contraindications` | TEXT | — | Contraindicatii (RO) |
| `contraindications_en` | TEXT | — | Contraindicatii (EN) |
| `ai_confidence` | DECIMAL(4,3) | — | Scor AI 0.000-1.000 |
| `status` | ENUM('pending','approved','rejected') | ✓ | Default: `pending`. Admin aproba/respinge |
| `created_at` | DATETIME | ✓ | Auto-generat |

**Flow moderare:** observatia se creeaza cu `status = 'pending'`. Din panoul admin se aproba sau se respinge. Pe harta apar doar cele cu `status = 'approved'`.

**Logica imagini:** imaginile sunt stocate pe disc in `uploads/images/poi/{id}/`. API-ul citeste folderul si returneaza:
- `primary_image` — primul fisier (sortat alfabetic), folosit in lista de pe harta
- `images[]` — toate fisierele, folosit in pagina de detalii
- La creare POI → folderul se creeaza automat
- La stergere POI → folderul se sterge automat

---

### 7. `comments`

Comentarii ale utilizatorilor pe observatii. Suporta reply-uri prin `parent_id`.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | Autorul |
| `poi_id` | INT, FK → points_of_interest.id | ✓ | Observatia comentata |
| `content` | TEXT | ✓ | Textul comentariului |
| `parent_id` | INT, FK → comments.id | — | NULL = comentariu root, altfel = reply la alt comentariu |
| `created_at` | DATETIME | ✓ | Auto-generat |

---

### 8. `notifications`

Notificari in-app pentru utilizatori.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | Destinatarul notificarii |
| `type` | ENUM('poi_created','poi_approved','poi_rejected','poi_pending','poi_edited','poi_commented') | ✓ | Tipul evenimentului |
| `title` | VARCHAR(255) | ✓ | Titlul notificarii |
| `message` | TEXT | ✓ | Mesajul complet |
| `is_read` | BOOLEAN | ✓ | Default: `FALSE` |
| `poi_id` | INT, FK → points_of_interest.id | — | Observatia asociata (ON DELETE SET NULL) |
| `plant_name` | VARCHAR(255) | — | Numele plantei (cached) |
| `reason` | VARCHAR(500) | — | Motivul respingerii |
| `created_at` | TIMESTAMP | ✓ | Auto-generat |

---

### 9. `favorites`

Plante favorite ale utilizatorilor.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `created_at` | TIMESTAMP | ✓ | Auto-generat |

**Constrangere:** UNIQUE KEY `unique_fav` pe `(user_id, plant_id)`.

---

### 10. `chat_history`

Istoricul conversatiilor cu chatbot-ul RAG.

| Camp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | — | NULL daca utilizator anonim. `ON DELETE SET NULL` |
| `question` | TEXT | ✓ | Intrebarea utilizatorului |
| `answer` | TEXT | ✓ | Raspunsul chatbot-ului |
| `created_at` | DATETIME | ✓ | Auto-generat |

---

### 11. `config`

Tabel singleton cu setarile hartii (Galati).

| Camp | Tip | Default | Descriere |
|------|-----|---------|-----------|
| `id` | INT, PK, AI | — | Intotdeauna `1` |
| `map_center_lat` | DECIMAL(10,7) | 45.4353000 | Centrul hartii — latitudine |
| `map_center_lng` | DECIMAL(10,7) | 28.0080000 | Centrul hartii — longitudine |
| `map_default_zoom` | INT | 13 | Zoom initial |
| `map_max_zoom` | INT | 18 | Zoom maxim |
| `map_min_zoom` | INT | 10 | Zoom minim |
| `tile_url` | VARCHAR(500) | OSM template | URL template tile-uri |
| `tile_attribution` | VARCHAR(500) | © OSM | Atribuirea hartii |
| `bounds_north` | DECIMAL(10,7) | — | Bounding box Galati — nord |
| `bounds_south` | DECIMAL(10,7) | — | Bounding box Galati — sud |
| `bounds_east` | DECIMAL(10,7) | — | Bounding box Galati — est |
| `bounds_west` | DECIMAL(10,7) | — | Bounding box Galati — vest |
| `active_model` | VARCHAR(100) | model_densenet121.h5 | Modelul AI activ pentru clasificare |

---

## Indexuri

| Index | Tabel | Coloane | Scop |
|-------|-------|---------|------|
| `idx_poi_plant` | points_of_interest | plant_id | Join rapid plante ↔ observatii |
| `idx_poi_user` | points_of_interest | user_id | Observatiile unui user |
| `idx_poi_status` | points_of_interest | status | Filtrare approved/pending |
| `idx_poi_coords` | points_of_interest | latitude, longitude | Cautare geografica |
| `idx_comments_poi` | comments | poi_id | Comentariile unei observatii |
| `idx_benefits_plant` | plant_benefits | plant_id | Beneficiile unei plante |
| `idx_contra_plant` | plant_contraindications | plant_id | Contraindicatiile unei plante |
| `idx_parts_plant` | plant_usable_parts | plant_id | Partile utilizabile |
| `idx_chat_user` | chat_history | user_id | Istoricul chat per user |
| `idx_notif_user` | notifications | user_id | Notificarile unui user |
| `idx_notif_read` | notifications | user_id, is_read | Notificari necitite |
| `idx_notif_created` | notifications | created_at | Ordonare cronologica |

---

## Fisiere SQL

| Fisier | Descriere |
|--------|-----------|
| `001_schema_final (1).sql` | Schema de baza — creeaza toate tabelele principale (users, plants, plant_usable_parts, plant_benefits, plant_contraindications, points_of_interest, comments, chat_history, config) + indexuri |
| `002_seed (1).sql` | Date seed: 1 config, 5 useri, 19 plante, ~38 parti utilizabile, 95 beneficii, ~62 contraindicatii, 16 observatii, 8 comentarii |
| `003_english_translations.sql` | Migrare: adauga coloane `_en` pe plants, plant_usable_parts, plant_benefits, plant_contraindications si populeaza traducerile |
| `004_backend_todo_migration.sql` | Migrare: creeaza tabelele notifications si favorites, adauga parent_id pe comments, adauga campuri noi pe points_of_interest (description, habitat, harvest_period, benefits, contraindications + variante _en) |

## Utilizare

```bash
# 1. Crearea schemei
mysql -u root -p < sql/001_schema_final\ \(1\).sql

# 2. Popularea cu date
mysql -u root -p < sql/002_seed\ \(1\).sql

# 3. Traduceri in engleza
mysql -u root -p < sql/003_english_translations.sql

# 4. Notificari, favorite, campuri noi POI
mysql -u root -p < sql/004_backend_todo_migration.sql
```

Schema face `DROP TABLE IF EXISTS` cu `FOREIGN_KEY_CHECKS = 0` la inceput, deci poate fi rerulata fara probleme. Migrarile 003 si 004 folosesc `IF NOT EXISTS` / verificari `information_schema` pentru a fi idempotente.

---

## Date seed

| Tabel | Nr. inregistrari |
|-------|:----------------:|
| config | 1 |
| users | 5 |
| plants | 19 |
| plant_usable_parts | ~38 |
| plant_benefits | 95 |
| plant_contraindications | ~62 |
| points_of_interest | 16 |
| comments | 8 |
| chat_history | 0 (se populeaza din aplicatie) |
| notifications | 0 (se populeaza din aplicatie) |
| favorites | 0 (se populeaza din aplicatie) |
