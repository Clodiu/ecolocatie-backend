# 🖥️ Setup VM Windows 11 - EcoLocație Backend
## Ghid pas cu pas (copy-paste)

---

## PASUL 1: Conectare la VM

### De la facultate (direct):
1. Deschide "Remote Desktop Connection" (Win + R → `mstsc`)
2. Scrie: `10.66.2.1`
3. Introdu user + parolă VM

### De acasă (prin VPN):
1. Settings → Network & Internet → VPN → Add a VPN connection
   - VPN Provider: `Windows (built-in)`
   - Connection name: `VPN_CTI`
   - Server: `vpn.cti.ugal.ro`
   - VPN type: `IKEv2`
   - Sign-in info: `Username and password`
   - Username: `username-ul tău CTI` (fără @cti.ugal.ro)
   - Password: parola ta CTI
2. Conectează-te la VPN (click pe iconița de rețea → VPN_CTI → Connect)
3. Deschide Remote Desktop → `10.66.2.1`

---

## PASUL 2: Instalare Node.js

1. Deschide browser pe VM
2. Mergi la: https://nodejs.org
3. Descarcă **Node.js 20 LTS** (Windows Installer .msi)
4. Instalează cu setările default (Next → Next → Install)
5. Verifică instalarea - deschide **PowerShell** (click dreapta pe Start → Terminal):

```powershell
node --version
# Ar trebui să afișeze: v20.x.x

npm --version
# Ar trebui să afișeze: 10.x.x
```

---

## PASUL 3: Instalare MySQL

1. Mergi la: https://dev.mysql.com/downloads/installer/
2. Descarcă **MySQL Installer for Windows** (mysql-installer-community)
3. La instalare alege **Custom** și selectează:
   - MySQL Server 8.x
   - MySQL Workbench (opțional, dar util pentru a vedea datele vizual)
4. Configurare:
   - Type: **Development Computer**
   - Authentication: **Use Legacy Authentication** (mai simplu)
   - Root Password: **setează o parolă și reține-o!**
5. Finish

6. Verifică instalarea în PowerShell:

```powershell
mysql --version
# Dacă nu merge, adaugă MySQL în PATH:
# Settings → System → About → Advanced system settings → Environment Variables
# Path → Edit → New → C:\Program Files\MySQL\MySQL Server 8.0\bin
```

7. Testează conexiunea:

```powershell
mysql -u root -p
# Introdu parola setată la instalare
# Ar trebui să vezi: mysql>
# Scrie: exit
```

---

## PASUL 4: Instalare Python (pentru modelul AI)

1. Mergi la: https://www.python.org/downloads/
2. Descarcă Python 3.11 sau 3.12
3. **IMPORTANT**: La instalare bifează **"Add Python to PATH"** !!
4. Instalează
5. Verifică:

```powershell
python --version
# Python 3.11.x sau 3.12.x

pip --version
```

6. Instalează TensorFlow (pentru modelul .h5):

```powershell
pip install tensorflow numpy pillow
```

---

## PASUL 5: Instalare ngrok

1. Mergi la: https://ngrok.com
2. Creează cont gratuit
3. Descarcă ngrok pentru Windows
4. Extrage ngrok.exe într-un folder (ex: `C:\ngrok\`)
5. Deschide PowerShell și autentifică-te:

```powershell
cd C:\ngrok
.\ngrok config add-authtoken TOKENUL_TAU_DE_PE_SITE
```

---

## PASUL 6: Setup proiect EcoLocație

1. Creează un folder pentru proiect:

```powershell
mkdir C:\ecolocatie
cd C:\ecolocatie
```

2. Copiază/extrage zip-ul `ecolocatie-backend.zip` aici
   (sau descarcă proiectul de pe GitHub dacă l-ai push-uit)

3. Navighează în folder:

```powershell
cd C:\ecolocatie\ecolocatie-backend
```

4. Instalează dependențele Node.js:

```powershell
npm install
```

Așteaptă să se termine (1-2 minute).

---

## PASUL 7: Creează baza de date

1. Deschide PowerShell și rulează scripturile SQL:

```powershell
cd C:\ecolocatie\ecolocatie-backend

# Creează tabelele
mysql -u root -p < sql\001_schema.sql

# Populează cu cele 19 plante
mysql -u root -p < sql\002_seed.sql
```

2. Verifică datele:

```powershell
mysql -u root -p ecolocatie

# În consola MySQL, rulează:
SELECT name_ro, name_latin FROM plants;
# Ar trebui să vezi 19 plante

SELECT p.name_ro, pb.benefit FROM plants p
JOIN plant_benefits pb ON p.id = pb.plant_id
WHERE p.name_ro = 'Mușețel';
# Ar trebui să vezi 5 beneficii

exit
```

---

## PASUL 8: Configurează .env

Deschide fișierul `.env` cu Notepad și modifică:

```powershell
notepad .env
```

Schimbă aceste valori:

```
DB_PASSWORD=PAROLA_TA_MYSQL_DE_LA_PASUL_3
JWT_SECRET=o_cheie_lunga_si_random_aici_2026
PYTHON_PATH=python
MODEL_PATH=./python/model.h5
```

Salvează și închide.

---

## PASUL 9: Copiază modelul AI

Copiază fișierul `.h5` (modelul tău antrenat) în:

```
C:\ecolocatie\ecolocatie-backend\python\model.h5
```

**IMPORTANT**: Verifică în `python/classify.py` că lista `CLASSES` are aceleași
nume și aceeași ordine ca folderele din dataset-ul tău de antrenare!

---

## PASUL 10: Pornește serverul

```powershell
cd C:\ecolocatie\ecolocatie-backend
npm run dev
```

Ar trebui să vezi:

```
  ╔═══════════════════════════════════════════╗
  ║        🌿 EcoLocație API v1.0.0          ║
  ║   Plante medicinale - Județul Galați      ║
  ╠═══════════════════════════════════════════╣
  ║   Server:  http://localhost:3000          ║
  ╚═══════════════════════════════════════════╝
  ✅ Conectat la MySQL
```

Testează în browser pe VM: http://localhost:3000

---

## PASUL 11: Expune cu ngrok

Deschide **un alt terminal PowerShell** (nu închide cel cu serverul!):

```powershell
cd C:\ngrok
.\ngrok http 3000
```

Vei vedea ceva de genul:

```
Forwarding    https://abc123.ngrok-free.app -> http://localhost:3000
```

**Acel URL (https://abc123.ngrok-free.app) este URL-ul public!**

Copiază-l și trimite-l echipei. Ei îl folosesc în aplicația Expo ca `BASE_URL`.

---

## PASUL 12: Testare finală

Din browser (pe orice dispozitiv):

```
https://abc123.ngrok-free.app/
→ Vezi info API

https://abc123.ngrok-free.app/api/plants
→ Vezi lista cu 19 plante

https://abc123.ngrok-free.app/api/plants?search=menta
→ Caută mentă
```

Din PowerShell (pe VM sau de pe alt PC):

```powershell
# Înregistrare
curl -X POST https://abc123.ngrok-free.app/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{"username":"test","email":"test@test.ro","password":"parola123"}'

# Login
curl -X POST https://abc123.ngrok-free.app/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"test@test.ro","password":"parola123"}'
# → Copiază token-ul din răspuns

# Lista plante cu sortare
curl "https://abc123.ngrok-free.app/api/plants?sort=name_ro&order=ASC"

# Caută plante bune pentru insomnie
curl "https://abc123.ngrok-free.app/api/plants?search=insomnie"
```

---

## 🔧 Troubleshooting

### "mysql nu e recunoscut ca comandă"
→ Adaugă MySQL în PATH:
  System Properties → Environment Variables → Path → Edit → New →
  `C:\Program Files\MySQL\MySQL Server 8.0\bin`

### "ECONNREFUSED la MySQL"
→ Verifică dacă MySQL Service rulează:
  Win + R → `services.msc` → caută "MySQL80" → Start

### "ngrok nu se conectează"
→ Verifică firewall-ul Windows:
  Windows Security → Firewall → Allow an app → Adaugă ngrok.exe

### "Port 3000 deja folosit"
→ Schimbă portul în `.env`: `PORT=3001`
→ Apoi: `.\ngrok http 3001`

### "Python nu e găsit"
→ Reinstalează Python cu "Add to PATH" bifat
→ Sau setează în `.env`: `PYTHON_PATH=C:\Python311\python.exe`

---

## 📋 Comenzi rapide (cheatsheet)

```powershell
# Pornește totul (2 terminale PowerShell):

# Terminal 1 - Server:
cd C:\ecolocatie\ecolocatie-backend
npm run dev

# Terminal 2 - ngrok:
cd C:\ngrok
.\ngrok http 3000
```

---

## ⏰ Pornire automată la boot (opțional)

Dacă vrei ca serverul să pornească automat când pornește VM-ul:

1. Creează un fișier `start-ecolocatie.bat`:

```bat
@echo off
cd C:\ecolocatie\ecolocatie-backend
start "EcoLocatie API" cmd /k "npm run start"
timeout /t 5
start "ngrok" cmd /k "cd C:\ngrok && ngrok http 3000"
```

2. Apasă Win + R → scrie `shell:startup` → Enter
3. Copiază `start-ecolocatie.bat` în folderul care se deschide

Acum la fiecare pornire a VM-ului, serverul și ngrok pornesc automat!
