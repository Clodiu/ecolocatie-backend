# Backend TODO — Cereri din Frontend

**Data:** 2026-03-26
**De la:** Frontend (React Native / Expo)
**Catre:** Backend (API)

---

## 1. API Endpoints necesare pentru Comments

Frontend-ul are acum tipul `Comment` definit si pregatit. Trebuie urmatoarele endpoint-uri:

```
GET    /api/pois/:id/comments          → Lista comentarii per observatie (paginat)
POST   /api/pois/:id/comments          → Adauga comentariu (body: { content })
DELETE /api/comments/:id               → Sterge comentariu (doar autorul sau admin)
```

**Response format pentru GET:**
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 2,
      "poi_id": 5,
      "content": "Am gasit aceeasi planta si eu aici!",
      "created_at": "2025-06-15T14:30:00Z",
      "author": "Maria Ionescu"
    }
  ],
  "total": 8
}
```

**Nota:** Frontend-ul va afisa `author` (first_name + last_name) — ideal sa fie inclus in response ca sa evitam request-uri suplimentare.

---

## 2. Endpoint pentru Plantele utilizatorului (My Plants)

```
GET /api/users/:id/plants             → Plantele unice observate de user (din POI-uri)
GET /api/users/:id/history            → Toate POI-urile user-ului, sortate desc by created_at
DELETE /api/users/:id/plants/:plantId → Sterge toate POI-urile user-ului pentru o planta
```

**Response GET /plants:**
```json
{
  "data": [
    {
      "plant": { ...plant_object... },
      "observation_count": 3,
      "last_observation_date": "2025-06-10T08:00:00Z"
    }
  ]
}
```

Alternativ, frontend-ul poate construi aceste date din `GET /api/pois?user_id=X`, dar un endpoint dedicat ar fi mai eficient.

---

## 3. Campuri de inclus in response-urile existente

### GET /api/plants/:id
- [x] `name_en` — deja in DB, trebuie doar inclus in response
- [x] `images[]` — lista completa de imagini din folder (pe langa `primary_image`)

### GET /api/pois si GET /api/pois/:id
- [x] `address` — deja in DB, trebuie inclus in response
- [x] `images[]` — toate imaginile din folderul POI-ului
- [ ] `comments_count` — numarul de comentarii (optional, util pe harta)

### GET /api/pois/:id (detail)
- [ ] `comments` — primele N comentarii inline (optional, evita request separat)

---

## 4. Reverse Geocoding la creare POI

Cand se creeaza un POI (POST /api/pois), daca `address` lipseste din body, backend-ul ar trebui sa faca reverse geocoding pe coordonatele `latitude`/`longitude` si sa populeze campul `address` automat.

Servicii gratuite: Nominatim (OpenStreetMap), sau Google Geocoding API.

---

## 5. Status enum pe POI

Frontend-ul foloseste acum `status: 'pending' | 'approved' | 'rejected'` (nu mai exista `is_approved` boolean). Confirmare ca API-ul returneaza deja `status` ca enum — **OK, deja implementat**.

---

## 6. Seed data — sincronizare

Frontend-ul mock-up a avut 20 de plante. DB-ul are 19 (din DATABASE.md). Verifica daca `Hrean` (planta #20) trebuie adaugata in seed sau daca frontend-ul trebuie sa-l scoata.

---

## 7. Traduceri in engleza pentru toate plantele

Frontend-ul are acum suport complet multilanguage (romana + engleza). Toate textele din UI sunt traduse, dar **datele plantelor vin din API doar in romana**. Cand utilizatorul schimba limba in engleza, descrierile, beneficiile, contraindicatiile etc. raman in romana.

### Campuri noi necesare pe fiecare planta (in DB + response API):

| Camp existent (RO) | Camp nou (EN) |
|---|---|
| `description` | `description_en` |
| `habitat` | `habitat_en` |
| `harvest_period` | `harvest_period_en` |
| `preparation` | `preparation_en` |
| `benefits[]` | `benefits_en[]` |
| `contraindications[]` | `contraindications_en[]` |
| `usable_parts[]` | `usable_parts_en[]` |

`name_en` exista deja in DB — trebuie doar populat pentru toate plantele.

### Traduceri propuse pentru toate plantele:

#### 1. Musetel (Matricaria chamomilla)
- **name_en:** Chamomile
- **description_en:** Annual herbaceous plant with white flowers and yellow center. Grows spontaneously in plains, roadsides, and wastelands.
- **parts_used_en:** flowers, aerial parts
- **benefits_en:** Digestive calmative and antispasmodic | Anti-inflammatory | Treatment for insomnia and anxiety | Remedy for skin conditions | Relieves menstrual pain
- **contraindications_en:** Allergy to Asteraceae family plants | Not recommended during pregnancy in large doses | May interact with anticoagulants
- **habitat_en:** Plains, roadsides, wastelands, sunny areas
- **harvest_period_en:** May - August
- **preparation_en:** Tea (infusion), compresses, baths, essential oil

#### 2. Sunatoare (Hypericum perforatum)
- **name_en:** St. John's Wort
- **description_en:** Perennial plant with yellow flowers and leaves with translucent dots. Grows in meadows and forest edges.
- **parts_used_en:** flowers, leaves, young stems
- **benefits_en:** Natural antidepressant | Wound and burn healing agent | Anti-inflammatory | Antiseptic | Relieves nervous disorders
- **contraindications_en:** Photosensitization (avoid sun exposure) | Interaction with SSRI antidepressants | Interaction with oral contraceptives | Not recommended during pregnancy
- **habitat_en:** Dry meadows, forest edges, wastelands
- **harvest_period_en:** June - August
- **preparation_en:** Tea, tincture, St. John's Wort oil (macerate)

#### 3. Coada-calului (Equisetum arvense)
- **name_en:** Horsetail
- **description_en:** Perennial flowerless plant with articulated green stems. Grows in moist areas near water.
- **parts_used_en:** sterile (green) stems
- **benefits_en:** Remineralizing (rich in silicon) | Natural diuretic | Helps heal bone fractures | Fights cellulite | Strengthens hair and nails
- **contraindications_en:** Not recommended for kidney failure | Do not use for more than 6 continuous weeks | Contraindicated during pregnancy and breastfeeding
- **habitat_en:** Moist areas, riverbanks, ditches, floodplains
- **harvest_period_en:** May - July
- **preparation_en:** Decoction, powder, liquid extract

#### 4. Tei (Tilia cordata)
- **name_en:** Linden
- **description_en:** Tall tree with highly fragrant yellowish-green flowers. Common in parks, alleys, and deciduous forests.
- **parts_used_en:** flowers, bracts
- **benefits_en:** Mild calmative and sedative | Antispasmodic | Diaphoretic (induces sweating) | Relieves colds and flu | Lowers blood pressure
- **contraindications_en:** Excessive consumption may affect the heart | Caution for people with heart problems | May cause drowsiness
- **habitat_en:** Deciduous forests, parks, alleys, gardens
- **harvest_period_en:** June - July
- **preparation_en:** Tea (infusion), linden honey

#### 5. Menta (Mentha piperita)
- **name_en:** Peppermint
- **description_en:** Aromatic perennial plant with oval, serrated leaves and a strong menthol scent.
- **parts_used_en:** leaves, flowering stems
- **benefits_en:** Relieves digestive disorders | Intestinal antispasmodic | Cooling and local analgesic effect | Nasal decongestant | Relieves headaches
- **contraindications_en:** Gastroesophageal reflux (may worsen) | Not recommended for children under 3 years | May interact with antacid medications
- **habitat_en:** Cultivated in gardens, also subspontaneous on riverbanks
- **harvest_period_en:** June - September
- **preparation_en:** Tea, essential oil, tincture

#### 6. Papadie (Taraxacum officinale)
- **name_en:** Dandelion
- **description_en:** Perennial herbaceous plant with yellow flowers and puff-type fruits. Extremely common in fields and meadows.
- **parts_used_en:** leaves, roots, flowers
- **benefits_en:** Powerful natural diuretic | Stimulates liver function | Depurative and detoxifying effect | Rich in vitamins A, C, K | Relieves constipation
- **contraindications_en:** Allergy to Asteraceae plants | Biliary obstruction | Interaction with diuretics and lithium
- **habitat_en:** Meadows, fields, gardens, roadsides — ubiquitous
- **harvest_period_en:** April - October (leaves); Autumn (roots)
- **preparation_en:** Tea, salads (young leaves), juice, root decoction

#### 7. Urzica (Urtica dioica)
- **name_en:** Stinging Nettle
- **description_en:** Perennial plant with leaves covered in stinging hairs. Grows in moist, shaded areas.
- **parts_used_en:** young leaves, roots, seeds
- **benefits_en:** Anti-anemic (rich in iron) | Diuretic and depurative | Anti-inflammatory | Relieves allergy symptoms | Strengthens hair
- **contraindications_en:** Severe heart or kidney failure | Interaction with anticoagulants | Not recommended during pregnancy (stimulates contractions)
- **habitat_en:** Moist, shaded areas, fences, riparian forests, ruins
- **harvest_period_en:** April - June (leaves); Autumn (roots)
- **preparation_en:** Tea, juice, soup, tincture

#### 8. Pelin (Artemisia absinthium)
- **name_en:** Wormwood
- **description_en:** Perennial plant with silvery leaves, strongly aromatic, with a very bitter taste.
- **parts_used_en:** leaves, flowering tops
- **benefits_en:** Stimulates appetite and digestion | Intestinal antiparasitic | Cholagogue effect (stimulates bile) | General tonic | Febrifuge
- **contraindications_en:** Toxic in large doses (thujone) | Strictly forbidden during pregnancy | Not to be administered to children | Not to be used for long periods
- **habitat_en:** Wastelands, roadsides, dry plains
- **harvest_period_en:** July - August
- **preparation_en:** Tea (short infusion), tincture, wormwood wine

#### 9. Coada-soricelului (Achillea millefolium)
- **name_en:** Yarrow
- **description_en:** Perennial plant with small white or pinkish flowers in corymbs and finely divided leaves.
- **parts_used_en:** flowering aerial parts
- **benefits_en:** Hemostatic (stops bleeding) | Digestive anti-inflammatory | Relieves menstrual cramps | Wound healing | Antiseptic
- **contraindications_en:** Allergy to Asteraceae | Pregnancy (stimulates contractions) | Interaction with anticoagulants
- **habitat_en:** Meadows, hayfields, roadsides — from plains to mountains
- **harvest_period_en:** June - September
- **preparation_en:** Tea, compresses, tincture, baths

#### 10. Cicoare (Cichorium intybus)
- **name_en:** Chicory
- **description_en:** Perennial plant with azure-blue flowers and a thick taproot. Common in fields.
- **parts_used_en:** roots, leaves, flowers
- **benefits_en:** Stimulates digestion and appetite | Hepatoprotective effect | Mild diuretic | Natural prebiotic (inulin) | Coffee substitute (roasted root)
- **contraindications_en:** Gallstones | Allergy to Asteraceae | May cause contact dermatitis
- **habitat_en:** Fields, roadsides, wastelands, dry meadows
- **harvest_period_en:** July - September (flowers); Autumn (roots)
- **preparation_en:** Root decoction, salad (leaves), chicory coffee

#### 11. Tataneasa (Symphytum officinale)
- **name_en:** Comfrey
- **description_en:** Robust perennial plant with large hairy leaves and pink-violet tubular flowers. Grows near water.
- **parts_used_en:** roots, leaves (external use only)
- **benefits_en:** Accelerates fracture healing | Powerful wound healer | Anti-inflammatory | Relieves joint pain | Treats sprains and bruises
- **contraindications_en:** NEVER administered internally (hepatotoxic pyrrolizidine alkaloids) | Do not apply on open wounds | Contraindicated during pregnancy and breastfeeding | External use max 4-6 weeks/year
- **habitat_en:** Floodplains, riverbanks, moist lowland areas
- **harvest_period_en:** Spring and autumn (roots); Summer (leaves)
- **preparation_en:** Ointment, poultices (external use only!)

#### 12. Maces (Rosa canina)
- **name_en:** Dog Rose / Rosehip
- **description_en:** Thorny shrub with pink flowers and red fruits (rosehips). Common at forest edges.
- **parts_used_en:** fruits (rosehips), petals
- **benefits_en:** Very rich in vitamin C | Immunostimulant | Powerful antioxidant | Mild laxative | Anti-inflammatory for joints
- **contraindications_en:** Kidney stones (oxalates) | May cause gastric discomfort in excess | Diabetics — contains natural sugars
- **habitat_en:** Forest edges, thickets, hedgerows, hills
- **harvest_period_en:** September - November (fruits)
- **preparation_en:** Tea, jam, syrup, marmalade

#### 13. Paducel (Crataegus monogyna)
- **name_en:** Hawthorn
- **description_en:** Thorny shrub or small tree with white flowers and small red fruits. Grows at forest edges.
- **parts_used_en:** flowers, fruits, leaves
- **benefits_en:** Cardiotonic — strengthens the heart muscle | Regulates blood pressure | Mild sedative | Antioxidant | Relieves palpitations
- **contraindications_en:** Interaction with cardiac medications (digoxin) | Not recommended without medical supervision for heart disease | Pregnancy and breastfeeding
- **habitat_en:** Forest edges, thickets, hedgerows
- **harvest_period_en:** May (flowers); September - October (fruits)
- **preparation_en:** Tea, tincture, extract

#### 14. Soc (Sambucus nigra)
- **name_en:** Elderberry
- **description_en:** Shrub or small tree with fragrant white flowers in corymbs and black fruits.
- **parts_used_en:** flowers, fruits
- **benefits_en:** Diaphoretic (induces sweating) | Antiviral (effective against flu) | Diuretic and depurative | Expectorant | Immunostimulant
- **contraindications_en:** Raw fruits are mildly toxic (must be cooked) | Leaves, bark and roots are TOXIC | Not recommended for autoimmune diseases
- **habitat_en:** Forests, riparian areas, hedges, from plains to premontane zone
- **harvest_period_en:** May - July (flowers); September (fruits)
- **preparation_en:** Flower tea, elderberry syrup, elderflower cordial, fruit jam

#### 15. Lavanda (Lavandula angustifolia)
- **name_en:** Lavender
- **description_en:** Aromatic perennial plant with violet-blue flowers arranged in spikes. Frequently cultivated.
- **parts_used_en:** flowers, essential oil
- **benefits_en:** Calming and relaxing | Relieves insomnia | Antiseptic and wound healing | Natural insect repellent | Relieves headaches
- **contraindications_en:** Undiluted essential oil may irritate the skin | May cause excessive drowsiness | Caution during pregnancy (first months)
- **habitat_en:** Cultivated in gardens and crops (plains, calcareous soils)
- **harvest_period_en:** June - August
- **preparation_en:** Tea, essential oil, scented sachets, bath

#### 16. Roinita / Melisa (Melissa officinalis)
- **name_en:** Lemon Balm
- **description_en:** Perennial plant with leaves that emit a lemon scent when rubbed. Cultivated and subspontaneous.
- **parts_used_en:** leaves, flowering tops
- **benefits_en:** Natural sedative and anxiolytic | Digestive antispasmodic | Relieves colic | Antiviral (cold sores) | Improves memory
- **contraindications_en:** Hypothyroidism (may suppress thyroid function) | May cause drowsiness | Interaction with sedatives
- **habitat_en:** Gardens, fences, shaded areas, cultivated and subspontaneous
- **harvest_period_en:** June - September
- **preparation_en:** Tea, tincture, essential oil

#### 17. Salvie (Salvia officinalis)
- **name_en:** Sage
- **description_en:** Aromatic perennial plant with velvety grayish-green leaves and violet flowers.
- **parts_used_en:** leaves
- **benefits_en:** Oropharyngeal antiseptic | Reduces excessive sweating | Relieves menopause symptoms | Anti-inflammatory | Stimulates memory
- **contraindications_en:** Epilepsy (thujone — convulsant effect) | Pregnancy and breastfeeding (reduces lactation) | Do not administer in large doses for long periods
- **habitat_en:** Cultivated in gardens, southern regions of Romania
- **harvest_period_en:** May - July
- **preparation_en:** Tea, gargling, seasoning, tincture

#### 18. Cimbru (Thymus vulgaris)
- **name_en:** Thyme
- **description_en:** Small aromatic perennial plant with woody stems and very small leaves.
- **parts_used_en:** flowering aerial parts
- **benefits_en:** Expectorant and antitussive | Powerful respiratory antiseptic | Antifungal | Stimulates digestion | Antioxidant
- **contraindications_en:** Severe arterial hypertension | Pregnancy (in large doses) | Active gastric ulcer
- **habitat_en:** Cultivated in gardens, dry plains, calcareous soils
- **harvest_period_en:** May - August
- **preparation_en:** Tea, syrup, seasoning, essential oil, inhalations

#### 19. Galbenele (Calendula officinalis)
- **name_en:** Marigold
- **description_en:** Annual plant with large orange or yellow flowers. Frequently cultivated in gardens.
- **parts_used_en:** flowers (ligules)
- **benefits_en:** Skin healing and regenerating | Anti-inflammatory | Mild antiseptic | Relieves gastric conditions | Antifungal
- **contraindications_en:** Allergy to Asteraceae | Pregnancy (emmenagogue effect) | Do not apply on deep infected wounds
- **habitat_en:** Cultivated in gardens, subspontaneous in wastelands
- **harvest_period_en:** June - October
- **preparation_en:** Tea, ointment, macerated oil, tincture

#### 20. Hrean (Armoracia rusticana)
- **name_en:** Horseradish
- **description_en:** Perennial plant with large leaves and a thick white root with a strong pungent taste.
- **parts_used_en:** roots, leaves
- **benefits_en:** Powerful natural antibiotic | Decongestant (sinusitis) | Stimulates digestion | Antiscorbutic effect (vitamin C) | Relieves rheumatic pain (poultices)
- **contraindications_en:** Gastric or duodenal ulcer | Severe kidney problems | Not to be administered to children under 4 years | Skin application may cause irritation
- **habitat_en:** Cultivated in gardens, subspontaneous near fences and moist areas
- **harvest_period_en:** Autumn (roots); Spring (leaves)
- **preparation_en:** Freshly grated, poultices, tincture, syrup with honey

---

## Prioritati sugerate

1. **Critic:** Include `name_en`, `address`, `images[]` in response-urile existente (modificari minime)
2. **Critic:** Adauga traducerile in engleza pentru toate plantele in DB (campuri `_en`) si include-le in response-urile API
3. **Important:** Endpoint-uri Comments (CRUD)
4. **Nice-to-have:** Endpoint-uri dedicate My Plants (alternativ, frontend-ul filtreaza din /api/pois)
5. **Nice-to-have:** Reverse geocoding automat la creare POI
