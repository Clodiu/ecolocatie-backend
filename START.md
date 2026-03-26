# EcoLocatie — Comenzi de pornire

## 1. Porneste serverul Express

```bash
cd c:\ecolocatie\ecolocatie-backend
node src/server.js
```

Ar trebui sa vezi:
```
Server:  http://localhost:3000
Conectat la MySQL
```

## 2. Porneste tunelul ngrok (alt terminal)

```bash
cd c:\ecolocatie\ecolocatie-backend
node_modules\ngrok\bin\ngrok.exe http 3000
```

Ngrok va afisa un URL public de forma:
```
https://xxxx-xxxx.ngrok-free.dev
```

## 3. Alternativ: porneste ambele dintr-o comanda

```bash
cd c:\ecolocatie\ecolocatie-backend
node src/ngrok.js
```

## Verificare rapida

Deschide in browser sau ruleaza:
```bash
curl http://localhost:3000/
curl http://localhost:3000/api/plants?limit=1
```

Prin ngrok (inlocuieste URL-ul):
```bash
curl -H "ngrok-skip-browser-warning: true" https://xxxx-xxxx.ngrok-free.dev/
```

## Daca portul 3000 e ocupat

```bash
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

## Daca ngrok da eroare "endpoint already online"

Inchide procesul ngrok existent:
```bash
taskkill /IM ngrok.exe /F
```
Apoi porneste din nou.

## Configurare ngrok (prima data)

```bash
cd c:\ecolocatie\ecolocatie-backend
npx ngrok config add-authtoken <TOKEN>
```
