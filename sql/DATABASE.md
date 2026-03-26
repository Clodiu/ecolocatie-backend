# EcoLocație — Documentația bazei de date

**Versiune:** 2.1  
**Proiect:** Concurs Severin Bumbaru 2026  
**Motor:** MySQL 8+ cu `utf8mb4_romanian_ci`

---

## Prezentare generală

Baza de date susține o aplicație de cartografiere a plantelor medicinale din zona Galați. Utilizatorii pot adăuga observații (sighting-uri) geolocalizate, identifica plante cu ajutorul AI-ului, consulta un chatbot RAG despre fitoterapie și interacționa prin comentarii.

### Diagrama relațiilor

```
users 1──N points_of_interest N──1 plants
  │                │                  │
  │                │    [poze: disc]  ├── N plant_benefits
  │                │    /images/poi/  ├── N plant_contraindications
  │                └── N comments     └── N plant_usable_parts
  │                         │
  └─────────────────────────┘

users 1──N chat_history

config (singleton — setări hartă)
```

---

## Tabele

### 1. `users`

Utilizatorii aplicației. Suportă două roluri: `admin` și `user`.

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | Identificator unic |
| `username` | VARCHAR(50), UNIQUE | ✓ | Numele de utilizator |
| `first_name` | VARCHAR(50) | — | Prenumele |
| `last_name` | VARCHAR(50) | — | Numele de familie |
| `email` | VARCHAR(100), UNIQUE | ✓ | Email, folosit la login |
| `password_hash` | VARCHAR(255) | ✓ | Hash bcrypt/argon2 |
| `phone` | VARCHAR(20) | — | Telefon |
| `birth_date` | DATE | — | Data nașterii |
| `role` | ENUM('user','admin') | ✓ | Default: `user` |
| `is_active` | BOOLEAN | ✓ | Default: `TRUE`. Admin poate dezactiva conturi |
| `profile_image` | VARCHAR(255) | — | URL avatar |
| `created_at` | DATETIME | ✓ | Auto-generat |

**Note backend:** `password_hash` nu stochează niciodată parola în clar. Frontend-ul colectează `first_name`, `last_name` la înregistrare. `profile_image` suportă upload avatar.

---

### 2. `plants`

Catalogul de plante medicinale (19 înregistrări în seed).

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | Identificator unic |
| `name_ro` | VARCHAR(100) | ✓ | Numele în română |
| `name_latin` | VARCHAR(100) | — | Numele științific |
| `name_en` | VARCHAR(100) | — | Numele în engleză |
| `family` | VARCHAR(100) | — | Familia botanică (ex: Asteraceae, Lamiaceae) |
| `description` | TEXT | — | Descriere detaliată (RO) |
| `description_en` | TEXT | — | Descriere detaliată (EN) |
| `habitat` | TEXT | — | Unde crește planta în natură (RO) |
| `habitat_en` | TEXT | — | Habitat (EN) |
| `harvest_period` | VARCHAR(150) | — | Perioada de recoltare (RO) |
| `harvest_period_en` | VARCHAR(150) | — | Harvest period (EN) |
| `preparation` | TEXT | — | Mod de preparare și utilizare (RO) |
| `preparation_en` | TEXT | — | Preparation method (EN) |
| `image_url` | VARCHAR(255) | — | Calea spre folderul cu poze (ex: `/images/plants/musetel`). API-ul citește fișierele de pe disc |
| `icon_color` | VARCHAR(7) | — | Cod hex culoare marker pe hartă. Default: `#4CAF50` |
| `folder_name` | VARCHAR(100) | ✓ | Numele folderului din datasetul AI |
| `created_at` | DATETIME | ✓ | Auto-generat |

**Câmpuri noi față de `001_schema.sql`:** `family`, `habitat`, `harvest_period`, `icon_color`.
**Câmpuri noi (traduceri EN):** `description_en`, `habitat_en`, `harvest_period_en`, `preparation_en` — adăugate prin `003_english_translations.sql`.
**Câmp eliminat:** `usable_parts` (TEXT) — mutat în tabelul normalizat `plant_usable_parts`.

**Logică imagini:** `image_url` stochează calea spre folder (ex: `/images/plants/musetel`), nu un fișier specific. API-ul citește fișierele de pe disc și returnează:
- `primary_image` — primul fișier din folder (sortat alfabetic), folosit în liste
- `images[]` — toate fișierele din folder, folosit în pagina de detalii/galerie

---

### 3. `plant_usable_parts`

Părțile utilizabile ale fiecărei plante, normalizat (fostul câmp `usable_parts` TEXT din `plants`).

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `part` | VARCHAR(100) | ✓ | Ex: „frunze", „rădăcina", „florile" (RO) |
| `part_en` | VARCHAR(100) | — | English translation |

---

### 4. `plant_benefits`

Beneficii medicinale (4–5 per plantă).

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `benefit` | VARCHAR(255) | ✓ | Un beneficiu medical (RO) |
| `benefit_en` | VARCHAR(255) | — | English translation |

---

### 5. `plant_contraindications`

Contraindicații (2–4 per plantă).

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `plant_id` | INT, FK → plants.id | ✓ | — |
| `contraindication` | VARCHAR(255) | ✓ | O contraindicație (RO) |
| `contraindication_en` | VARCHAR(255) | — | English translation |

---

### 6. `points_of_interest`

Observațiile (sighting-urile) de plante pe hartă.

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | Cine a creat observația |
| `plant_id` | INT, FK → plants.id | ✓ | Planta identificată |
| `latitude` | DECIMAL(10,7) | ✓ | Coordonate GPS |
| `longitude` | DECIMAL(10,7) | ✓ | Coordonate GPS |
| `address` | VARCHAR(255) | — | Adresa (geocoding invers) |
| `comment` | TEXT | — | Comentariu la observație |
| `ai_confidence` | DECIMAL(4,3) | — | Scor AI 0.000–1.000. Frontend-ul afișează top 3 cu procent |
| `status` | ENUM('pending','approved','rejected') | ✓ | Default: `pending`. Admin aprobă/respinge |
| `created_at` | DATETIME | ✓ | Auto-generat |

**Flow moderare:** observația se creează cu `status = 'pending'`. Din panoul admin se aprobă sau se respinge. Pe hartă apar doar cele cu `status = 'approved'`.

**Logică imagini:** imaginile sunt stocate pe disc în `uploads/images/poi/{id}/`. API-ul citește folderul și returnează:
- `primary_image` — primul fișier (sortat alfabetic), folosit în lista de pe hartă
- `images[]` — toate fișierele, folosit în pagina de detalii
- La creare POI → folderul se creează automat
- La ștergere POI → folderul se șterge automat

---

### 7. `comments`

Comentarii ale utilizatorilor pe observații.

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | ✓ | Autorul |
| `poi_id` | INT, FK → points_of_interest.id | ✓ | Observația comentată |
| `content` | TEXT | ✓ | Textul comentariului |
| `created_at` | DATETIME | ✓ | Auto-generat |

---

### 8. `chat_history`

Istoricul conversațiilor cu chatbot-ul RAG.

| Câmp | Tip | Obligatoriu | Descriere |
|------|-----|:-----------:|-----------|
| `id` | INT, PK, AI | ✓ | — |
| `user_id` | INT, FK → users.id | — | NULL dacă utilizator anonim. `ON DELETE SET NULL` |
| `question` | TEXT | ✓ | Întrebarea utilizatorului |
| `answer` | TEXT | ✓ | Răspunsul chatbot-ului |
| `created_at` | DATETIME | ✓ | Auto-generat |

---

### 9. `config`

Tabel singleton cu setările hărții (Galați).

| Câmp | Tip | Default | Descriere |
|------|-----|---------|-----------|
| `id` | INT, PK, AI | — | Întotdeauna `1` |
| `map_center_lat` | DECIMAL(10,7) | 45.4353000 | Centrul hărții — latitudine |
| `map_center_lng` | DECIMAL(10,7) | 28.0080000 | Centrul hărții — longitudine |
| `map_default_zoom` | INT | 13 | Zoom inițial |
| `map_max_zoom` | INT | 18 | Zoom maxim |
| `map_min_zoom` | INT | 10 | Zoom minim |
| `tile_url` | VARCHAR(500) | OSM template | URL template tile-uri |
| `tile_attribution` | VARCHAR(500) | © OSM | Atribuirea hărții |
| `bounds_north` | DECIMAL(10,7) | — | Bounding box Galați — nord |
| `bounds_south` | DECIMAL(10,7) | — | Bounding box Galați — sud |
| `bounds_east` | DECIMAL(10,7) | — | Bounding box Galați — est |
| `bounds_west` | DECIMAL(10,7) | — | Bounding box Galați — vest |

---

## Indexuri

| Index | Tabel | Coloane | Scop |
|-------|-------|---------|------|
| `idx_poi_plant` | points_of_interest | plant_id | Join rapid plante ↔ observații |
| `idx_poi_user` | points_of_interest | user_id | Observațiile unui user |
| `idx_poi_status` | points_of_interest | status | Filtrare approved/pending |
| `idx_poi_coords` | points_of_interest | latitude, longitude | Căutare geografică |
| `idx_comments_poi` | comments | poi_id | Comentariile unei observații |
| `idx_benefits_plant` | plant_benefits | plant_id | Beneficiile unei plante |
| `idx_contra_plant` | plant_contraindications | plant_id | Contraindicațiile unei plante |
| `idx_parts_plant` | plant_usable_parts | plant_id | Părțile utilizabile |
| `idx_chat_user` | chat_history | user_id | Istoricul chat per user |

---

## Diferențe față de versiunile anterioare

### Ce s-a schimbat față de `001_schema.sql` (schema inițială)

1. **`users`** — câmpuri noi: `first_name`, `last_name`, `phone`, `birth_date`, `is_active`, `profile_image`
2. **`plants`** — câmpuri noi: `family`, `habitat`, `harvest_period`, `icon_color`. Câmpul `usable_parts` (TEXT) a fost eliminat
3. **`plant_usable_parts`** — tabel nou, normalizează fostul câmp `usable_parts`
4. **`points_of_interest`** — câmpuri noi: `ai_confidence`, `image_url`
5. **`config`** — tabel nou, stochează setările hărții
6. **Indexuri noi:** `idx_poi_images_poi`, `idx_chat_user`

### Ce s-a schimbat față de `schema_final.sql` (output Claude Code)

1. **`points_of_interest.image_url`** — adăugat (frontend-ul mockup-ului folosește un singur `image_url` per observație, pe lângă tabelul `poi_images`)
2. **Indexuri noi:** `idx_poi_images_poi`, `idx_chat_user`
3. **Seed complet** — acum include: 19 plante (aliniate cu datasetul AI), 5 useri cu toate câmpurile, 16 observații cu `ai_confidence` și coordonate reale Galați, imagini POI, comentarii, rândul `config`

### Ce s-a schimbat în `003_english_translations.sql` (migrare traduceri)

1. **`plants`** — coloane noi: `description_en`, `habitat_en`, `harvest_period_en`, `preparation_en`
2. **`plant_usable_parts`** — coloană nouă: `part_en`
3. **`plant_benefits`** — coloană nouă: `benefit_en`
4. **`plant_contraindications`** — coloană nouă: `contraindication_en`
5. **Toate cele 19 plante** au traduceri complete în engleză populate prin UPDATE

### Ce s-a schimbat în seed față de `002_seed.sql` (seed-ul inițial)

1. **Users** — acum 5 useri cu `first_name`, `last_name`, `phone`, `birth_date`, `is_active`
2. **Plants** — adăugate `family`, `habitat`, `harvest_period`, `icon_color` per plantă
3. **plant_usable_parts** — date noi, normalizate din fostul câmp TEXT
4. **points_of_interest** — 16 observații cu coordonate reale din Galați, `ai_confidence`, `image_url`, status `approved`
5. **poi_images** — imagini asociate observațiilor
6. **comments** — 8 comentarii pe diverse observații
7. **config** — rând singleton cu bounding box Galați

---

## Date seed

| Tabel | Nr. înregistrări |
|-------|:----------------:|
| config | 1 |
| users | 5 |
| plants | 19 |
| plant_usable_parts | ~38 |
| plant_benefits | 95 |
| plant_contraindications | ~62 |
| points_of_interest | 16 |
| poi_images | 18 |
| comments | 8 |
| chat_history | 0 (se populează din aplicație) |

---

## Utilizare

```bash
# 1. Crearea schemei
mysql -u root -p < sql/001_schema_final.sql

# 2. Popularea cu date
mysql -u root -p < sql/002_seed.sql

# 3. Traduceri în engleză (migrare — adaugă coloane _en și populează traducerile)
mysql -u root -p < sql/003_english_translations.sql
```

Schema face `DROP TABLE IF EXISTS` cu `FOREIGN_KEY_CHECKS = 0` la început, deci poate fi rerulată fără probleme.

### Migrări

| Fișier | Descriere |
|--------|-----------|
| `003_english_translations.sql` | Adaugă coloane `_en` pe `plants`, `plant_usable_parts`, `plant_benefits`, `plant_contraindications` și populează traducerile în engleză pentru toate cele 19 plante |
