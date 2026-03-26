# 🌿 EcoLocație Backend

## Identificarea plantelor medicinale din județul Galați
### Concursul Severin Bumbaru 2026

---

## Structura proiectului

```
ecolocatie-backend/
├── sql/
│   ├── 001_schema.sql          # Crearea tabelelor
│   └── 002_seed.sql            # Date: 19 plante + beneficii + contraindicații
├── src/
│   ├── config/
│   │   └── db.js               # Conexiune MySQL
│   ├── middleware/
│   │   ├── auth.js             # JWT authentication
│   │   └── upload.js           # Multer - upload imagini
│   ├── routes/
│   │   ├── auth.js             # /api/auth (register, login, me)
│   │   ├── plants.js           # /api/plants (CRUD + search + sort)
│   │   ├── pois.js             # /api/pois (CRUD + GPS filter)
│   │   ├── comments.js         # /api/comments (CRUD)
│   │   ├── ai.js               # /api/identify + /api/chat (AI)
│   │   └── admin.js            # /api/admin (users, moderation)
│   └── server.js               # Entry point Express
├── python/
│   └── classify.py             # Script clasificare cu model .h5
├── uploads/images/             # Imagini uploadate
├── .env                        # Variabile de mediu
├── package.json
└── README.md
```

## Setup pe VM (pas cu pas)

### 1. Instalează Node.js
Descarcă Node.js 20 LTS de pe https://nodejs.org (pe Windows)

### 2. Instalează MySQL
Descarcă MySQL Community Server de pe https://dev.mysql.com/downloads/
La instalare, setează parola root.

### 3. Clonează/copiază proiectul pe VM

### 4. Instalează dependențele
```bash
cd ecolocatie-backend
npm install
```

### 5. Configurează .env
Editează fișierul `.env` cu parola ta MySQL și alte setări.

### 6. Creează baza de date
```bash
mysql -u root -p < sql/001_schema.sql
mysql -u root -p < sql/002_seed.sql
```

### 7. Pornește serverul
```bash
npm run dev
```
API-ul rulează pe http://localhost:3000

### 8. Expune cu ngrok
```bash
ngrok http 3000
```
Primești un URL public gen https://abc123.ngrok-free.app

### 9. (Opțional) Instalează Ollama pentru chatbot
```
Descarcă de pe https://ollama.com
ollama pull gemma
```

### 10. (Opțional) Python pentru model AI
```bash
pip install tensorflow numpy
```
Copiază modelul .h5 în folderul python/

## Testare rapidă cu curl

### Register
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.ro","password":"test123"}'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.ro","password":"test123"}'
```

### Lista plante
```bash
curl http://localhost:3000/api/plants
```

### Caută plante
```bash
curl "http://localhost:3000/api/plants?search=musetel"
```

### Identifică plantă (upload imagine)
```bash
curl -X POST http://localhost:3000/api/identify \
  -F "image=@poza_planta.jpg"
```

### Chat cu AI
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"question":"Ce plantă e bună pentru dureri de cap?"}'
```
