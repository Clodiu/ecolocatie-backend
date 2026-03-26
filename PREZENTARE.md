# EcoLocatie — Material prezentare

---

## 1. Prezentare generala

**EcoLocatie** este o aplicatie mobila de cartografiere a plantelor medicinale din judetul Galati. Utilizatorii pot:

- Fotografia o planta si o identifica automat cu ajutorul inteligentei artificiale
- Marca locatia pe harta si crea o observatie publica
- Consulta un chatbot specializat in fitoterapie
- Explora un catalog de 19 plante medicinale cu beneficii, contraindicatii si mod de preparare
- Interactiona prin comentarii si favorite

Aplicatia este bilingva (romana/engleza) si include un panou de administrare cu moderare, statistici si configurare.

---

## 2. Arhitectura aplicatiei

```
┌─────────────────────────────────────────────────────────────┐
│                    MASINA VIRTUALA (VM)                      │
│              16 GB RAM · 8 vCPU · 2 GB VRAM                │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │  Node.js +   │   │   MySQL 8    │   │    Ollama      │  │
│  │  Express API │──→│  11 tabele   │   │  (gemma3:1b)   │  │
│  │  (port 3000) │   │  utf8mb4     │   │  (port 11434)  │  │
│  └──────┬───────┘   └──────────────┘   └───────▲────────┘  │
│         │                                      │            │
│         │  subprocess                  HTTP     │            │
│         ▼                                      │            │
│  ┌──────────────┐                     ┌────────┴────────┐  │
│  │   Python +   │                     │  Chatbot RAG    │  │
│  │  TensorFlow  │                     │  (cautare DB +  │  │
│  │  (classify)  │                     │   context AI)   │  │
│  └──────────────┘                     └─────────────────┘  │
│         │                                                   │
│      ngrok (tunel public)                                   │
│         │                                                   │
└─────────┼───────────────────────────────────────────────────┘
          ▼
   ┌──────────────┐
   │  React Native │
   │  (Expo) App   │
   │   Frontend    │
   └──────────────┘
```

**Flow principal — Identificare planta:**
1. Utilizatorul fotografiaza o planta din aplicatia mobila
2. Imaginea se trimite la API (`POST /api/identify`)
3. Backend-ul salveaza imaginea temporar si apeleaza scriptul Python
4. Python incarca modelul CNN (DenseNet-121) si clasifica imaginea
5. Backend-ul potriveste rezultatul cu planta din baza de date
6. Returneaza planta identificata cu beneficii, contraindicatii si scor de incredere

**Flow chatbot:**
1. Utilizatorul pune o intrebare despre plante medicinale
2. Backend-ul extrage cuvinte cheie (stemming romanesc + normalizare diacritice)
3. Cauta plante relevante in baza de date (RAG — Retrieval-Augmented Generation)
4. Construieste un context cu informatii despre plantele gasite
5. Trimite contextul + intrebarea la Ollama (Gemma 3 1B)
6. Returneaza raspunsul generat, ancorat in date reale din baza de date

---

## 3. Stack tehnologic

### Backend (Node.js)

| Tehnologie | Versiune | Rol |
|------------|----------|-----|
| **Node.js** | 20.x | Runtime JavaScript pe server — executa codul backend-ului |
| **Express** | 4.18 | Framework web minimalist — defineste rutele API si gestioneaza cererile HTTP |
| **MySQL 2** | 3.6 | Driver MySQL cu suport `async/await` — conexiune la baza de date prin pool de 10 conexiuni |
| **bcrypt** | 5.1 | Hashing parole — transforma parolele in hash-uri ireversibile pentru securitate |
| **jsonwebtoken** | 9.0 | Autentificare JWT — genereaza si valideaza tokeni de sesiune (expira dupa 7 zile) |
| **Helmet** | 7.1 | Securitate HTTP — adauga headere de protectie impotriva atacurilor web comune (XSS, clickjacking) |
| **CORS** | 2.8 | Cross-Origin Resource Sharing — permite aplicatiei mobile sa comunice cu API-ul |
| **Multer** | 1.4 | Upload fisiere — proceseaza imaginile uploadate (JPG/PNG/WebP, max 10 MB) |
| **Morgan** | 1.10 | Logging — inregistreaza fiecare cerere HTTP in consola pentru debugging |
| **express-rate-limit** | 7.1 | Protectie anti-abuz — limiteaza la 1000 cereri / 15 minute per adresa IP |
| **Axios** | 1.6 | Client HTTP — folosit pentru comunicarea cu Ollama si reverse geocoding (Nominatim) |
| **dotenv** | 16.3 | Variabile de mediu — incarca configuratia din fisierul `.env` |

### Dezvoltare

| Tehnologie | Rol |
|------------|-----|
| **Nodemon** | Auto-restart server la modificari de cod — accelereaza dezvoltarea |
| **ngrok** | Tunel public — expune serverul local pe internet pentru testare pe telefon |

### Inteligenta artificiala (Python)

| Tehnologie | Rol |
|------------|-----|
| **TensorFlow / Keras** | Framework deep learning — incarca si ruleaza modelele CNN de clasificare |
| **NumPy** | Procesare numerica — manipulare matrice de pixeli pentru preprocesare imagini |
| **Pillow** | Procesare imagini — redimensionare la input-ul modelului |

### AI — Modele de clasificare

| Model | Arhitectura | Descriere |
|-------|-------------|-----------|
| **DenseNet-121** | Transfer learning | Model preantrenat pe ImageNet, adaptat pe datasetul propriu. Cel mai precis pe seturi mici de date |
| **ResNet-50** | Transfer learning | Echilibru intre viteza si acuratete. 50 straturi cu conexiuni reziduale |
| **CNN Custom** | Antrenat de la zero | Retea convolutionala proprie, mai usoara si mai rapida |

Toate cele 3 modele clasifica aceleasi **19 clase** (plante medicinale). Adminul poate schimba modelul activ din panoul de administrare fara a reporni serverul.

### AI — Chatbot RAG

| Componenta | Detalii |
|------------|---------|
| **Ollama** | Server local de inferenta LLM — ruleaza modele de limbaj fara cloud |
| **Gemma 3 1B** | Model de limbaj Google cu 1 miliard de parametri (~815 MB). Mic, rapid, potrivit pentru hardware limitat |
| **RAG** | Retrieval-Augmented Generation — chatbot-ul cauta informatii in baza de date inainte de a genera raspunsul, evitand halucinatiile |

Parametri chatbot: `temperature: 0.4` (raspunsuri factuale), `context: 4096 tokeni`, `max raspuns: 400 tokeni`, coada seriala (1 cerere la un moment dat).

### Baza de date

| Tehnologie | Detalii |
|------------|---------|
| **MySQL 8** | Motor relational — structura rigida, relatii intre tabele, tranzactii ACID |
| **utf8mb4_romanian_ci** | Collation romanesc — sortare corecta cu diacritice (a < a < b) si suport emoji |

### Infrastructura

| Tehnologie | Rol |
|------------|-----|
| **Windows Server** | Sistem de operare pe masina virtuala |
| **ngrok** | Expune API-ul pe internet cu HTTPS automat — inlocuieste nevoia unui domeniu si certificat SSL |

---

## 4. Baza de date

### Diagrama relatiilor

```
users 1──N points_of_interest N──1 plants
  │                │                  │
  │                │                  ├── N plant_benefits
  │                │                  ├── N plant_contraindications
  │                └── N comments     └── N plant_usable_parts
  │                         │
  └─────────────────────────┘

users 1──N notifications ──N points_of_interest
users 1──N favorites N──1 plants
users 1──N chat_history

config (singleton — setari harta)
```

### Cele 11 tabele

| Tabel | Inregistrari seed | Descriere |
|-------|:-----------------:|-----------|
| `users` | 5 | Utilizatori cu roluri (admin/user), avatar, date personale |
| `plants` | 19 | Catalog plante medicinale cu descrieri bilingve |
| `plant_benefits` | 95 | Beneficii medicinale per planta (4-5 fiecare) |
| `plant_contraindications` | ~62 | Contraindicatii per planta (2-4 fiecare) |
| `plant_usable_parts` | ~38 | Parti utilizabile ale plantei (frunze, flori, radacina) |
| `points_of_interest` | 16 | Observatii geolocalizate pe harta cu status de moderare |
| `comments` | 8 | Comentarii pe observatii cu suport reply-uri (parent_id) |
| `notifications` | 0 | Notificari in-app (6 tipuri de evenimente) |
| `favorites` | 0 | Plante favorite per utilizator |
| `chat_history` | 0 | Istoricul conversatiilor cu chatbot-ul |
| `config` | 1 | Setari harta (centru Galati, zoom, bounds, model AI activ) |

### Multilingv

Toate informatiile despre plante au traduceri in engleza:
- `plants`: description_en, habitat_en, harvest_period_en, preparation_en
- `plant_benefits`: benefit_en
- `plant_contraindications`: contraindication_en
- `plant_usable_parts`: part_en
- `points_of_interest`: description_en, habitat_en, comment_en, etc.

API-ul returneaza o singura limba per request prin parametrul `?lang=ro|en`.

---

## 5. Pipeline AI

### Clasificare plante (Computer Vision)

```
Fotografie telefon
      │
      ▼
  POST /api/identify (imagine)
      │
      ▼
  Python classify.py
  ┌─────────────────────────────┐
  │ 1. Incarca model .h5        │
  │ 2. Redimensioneaza imaginea │
  │ 3. Normalizeaza pixeli /255 │
  │ 4. model.predict()          │
  │ 5. Top prediction + scor    │
  └─────────────────────────────┘
      │
      ▼
  Match cu plants.folder_name
      │
      ▼
  Raspuns: planta + beneficii + contraindicatii + scor AI
```

**19 clase clasificate:** Aloe Vera, Brusture, Coada soricelului, Coltii babei, Floarea soarelui, Galbenele, Hibiscus, Iasomie, Lavanda, Menta, Musetel, Papadie, Pelin, Rostopasca, Salvie, Sunatoare, Trandafir, Urzica, Valeriana

### Chatbot RAG (Retrieval-Augmented Generation)

```
Intrebare utilizator: "Ce beneficii are musetelul?"
      │
      ▼
  Normalizare diacritice + stemming romanesc
      │
      ▼
  Cautare in DB: plante cu match pe beneficii, nume, descrieri
      │
      ▼
  Context construit din max 3 plante relevante
      │
      ▼
  Ollama (Gemma 3 1B) + system prompt + context + intrebare
      │
      ▼
  Raspuns generat, ancorat in date reale (nu halucinatii)
```

**De ce RAG?** Modelul de limbaj nu inventeaza informatii — raspunde strict pe baza datelor din baza de date. Daca nu gaseste informatii relevante, spune ca nu stie.

---

## 6. Infrastructura server (Masina Virtuala)

### Specificatii hardware

| Resursa | Valoare | Utilizare |
|---------|---------|-----------|
| **RAM** | 16 GB | ~2 GB Ollama (model Gemma in memorie) + ~1 GB TensorFlow + ~0.5 GB MySQL + ~0.3 GB Node.js |
| **VRAM** | 2 GB | Disponibila pentru accelerare GPU a inferentei TensorFlow (optional) |
| **vCPU** | 8 nuclee | Procesare paralela: server API + clasificare AI + chatbot + baza de date |

### Ce ruleaza pe VM

| Serviciu | Port | Memorie aprox. |
|----------|------|----------------|
| Node.js + Express API | 3000 | ~300 MB |
| MySQL 8 Server | 3306 | ~500 MB |
| Ollama (server + model) | 11434 | ~2 GB |
| TensorFlow (la cerere) | — | ~1 GB per clasificare |
| ngrok (tunel HTTPS) | 4040 | ~30 MB |

### Securitate

- **JWT** cu expirare 7 zile pentru autentificare
- **bcrypt** pentru hash-uri de parole ireversibile
- **Helmet** pentru headere HTTP de protectie
- **Rate limiting** — 1000 cereri / 15 min per IP
- **Validare upload** — doar JPG/PNG/WebP, max 10 MB
- **HTTPS automat** prin ngrok

---

## 7. De ce self-hosted si nu Supabase?

### Limitari Supabase pentru acest proiect

| Problema | Detaliu |
|----------|---------|
| **Nu poate rula modele AI local** | Supabase nu ofera compute pentru TensorFlow sau Ollama. Ar fi trebuit sa folosim API-uri externe platite (Google Vision, OpenAI) — cost recurent si dependenta de internet |
| **Nu poate rula Ollama** | Chatbot-ul RAG necesita un server de inferenta LLM local. Supabase nu permite procese long-running sau servere custom pe infrastructura lor |
| **Latenta clasificare** | Clasificarea unei imagini dureaza 1-3 secunde local. Prin API extern ar adauga inca 2-5 secunde de latenta retea + procesare cloud |
| **Cost** | Supabase Free Tier: 500 MB DB, 1 GB storage, 50.000 cereri/luna. Proiectul nostru depaseste rapid aceste limite cu imaginile uploadate si cererile de clasificare |
| **Control limitat** | Nu putem schimba modelul AI din panoul admin, nu putem rula Python, nu putem configura Ollama |

### Avantajele arhitecturii self-hosted

| Avantaj | Detaliu |
|---------|---------|
| **AI complet offline** | Clasificarea si chatbot-ul functioneaza fara internet. Datele utilizatorilor nu parasesc serverul |
| **Control total** | Putem schimba modelul AI, ajusta parametrii chatbot-ului, modifica pipeline-ul — totul din panoul admin |
| **Fara costuri recurente** | Nu platim per cerere API. O masina virtuala cu 16 GB RAM acopera toate nevoile |
| **Performanta previzibila** | Timpul de raspuns depinde doar de hardware-ul nostru, nu de latenta unui serviciu extern |
| **Fara vendor lock-in** | Nu depindem de un furnizor specific. Putem muta pe orice server cu Node.js, MySQL si Python |
| **Confidentialitate date** | Imaginile si datele utilizatorilor raman pe serverul nostru. Important pentru o aplicatie care colecteaza locatii GPS |

### Rezumat

Supabase ar fi fost potrivit pentru un CRUD simplu cu autentificare. Dar componentele AI ale proiectului (clasificare CNN + chatbot RAG) necesita compute dedicat pe care un BaaS (Backend-as-a-Service) nu il poate oferi. Arhitectura self-hosted ne da libertatea sa rulam modele de deep learning, un server de inferenta LLM si un pipeline complet de procesare imagini — totul pe o singura masina virtuala, fara costuri recurente si fara dependenta de servicii externe.
