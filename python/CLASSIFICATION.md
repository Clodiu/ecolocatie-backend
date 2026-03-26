# EcoLocație — Clasificare plante medicinale

## Prezentare generală

Clasificarea imaginilor se face prin scriptul `classify.py`, apelat din backend-ul Node.js ca subprocess. Scriptul primește calea spre o imagine, o procesează cu modelul Keras `.h5` activ și returnează predicția ca JSON pe `stdout`.

---

## Modele disponibile

| Fișier | Arhitectură | Descriere |
|--------|-------------|-----------|
| `model_cnn_custom.h5` | CNN custom | Rețea convoluțională antrenată de la zero pe datasetul propriu. Mai ușoară, mai rapidă. |
| `model_densenet121.h5` | DenseNet-121 | Transfer learning din DenseNet121 preantrenat pe ImageNet. Mai precisă pe seturi mici. |
| `model_resnet50.h5` | ResNet-50 | Transfer learning din ResNet50. Bun echilibru între viteză și acuratețe. |

Toate modelele clasifică aceleași **19 clase** (plante medicinale), în aceeași ordine:

```
Aloe Vera, Brusture, Coada soricelului, Coltii babei, Floarea soarelui,
Galbenele, Hibiscus, Iasomie, Lavanda, Menta, Musetel, Papadie, Pelin,
Rostopasca, Salvie, Sunatoare, Trandafir, Urzica, Valeriana
```

---

## Cum funcționează clasificarea

```
Frontend  →  POST /api/identify (multipart, câmpul "image")
                ↓
            Node.js (ai.js)
            1. Salvează imaginea temporar în uploads/
            2. Citește modelul activ din tabelul config (câmpul active_model)
            3. Apelează: python classify.py <cale_imagine> <model.h5>
                ↓
            Python (classify.py)
            1. Încarcă modelul .h5 cu TensorFlow/Keras
            2. Redimensionează imaginea la input_shape al modelului
            3. Normalizează pixelii (÷ 255)
            4. Rulează model.predict()
            5. Returnează JSON pe stdout:
               {
                 "class": "Musetel",
                 "confidence": 0.94,
                 "all_predictions": { "Musetel": 0.94, "Papadie": 0.03, ... }
               }
                ↓
            Node.js
            1. Parsează JSON din stdout
            2. Caută planta în DB după folder_name
            3. Returnează răspunsul complet către frontend
```

---

## Preprocesarea imaginii

1. **Redimensionare** — la dimensiunea input-ului modelului (detectată automat din `model.input_shape`)
2. **Normalizare** — valorile pixelilor împărțite la 255 → interval `[0.0, 1.0]`
3. **Batch dimension** — array-ul e extins cu `np.expand_dims(..., axis=0)` pentru a simula un batch de 1 imagine

---

## Apelarea scriptului

```bash
# Sintaxă
python classify.py <cale_imagine> [model.h5]

# Exemple
python classify.py /tmp/upload.jpg model_cnn_custom.h5
python classify.py /tmp/upload.jpg model_densenet121.h5
python classify.py /tmp/upload.jpg model_resnet50.h5

# Dacă modelul lipsește, se folosește model_cnn_custom.h5 (default)
python classify.py /tmp/upload.jpg
```

---

## Schimbarea modelului activ (admin)

Modelul activ se stochează în tabelul `config` (câmpul `active_model`). Adminul îl poate schimba din panoul de administrare fără a reporni serverul.

```
GET  /api/admin/model        → returnează modelul activ + lista modelelor disponibile
PUT  /api/admin/model        → { "model": "model_resnet50.h5" } → schimbă modelul activ
```

La fiecare request `/api/identify`, backend-ul citește `active_model` din DB și îl trimite ca argument scriptului Python.

---

## Răspuns JSON

```json
{
  "identified": true,
  "confidence": 0.94,
  "plant": {
    "id": 11,
    "name_ro": "Mușețel",
    "name_latin": "Matricaria chamomilla",
    "description": "...",
    "benefits": ["Calmant natural", "..."],
    "contraindications": ["Alergie la Asteraceae", "..."]
  },
  "image_url": "/uploads/images/1234567890.jpg"
}
```

---

## Dependențe Python

```
tensorflow >= 2.10
numpy
pillow
```

Instalare:
```bash
pip install tensorflow numpy pillow
```
