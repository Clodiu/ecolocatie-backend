-- ============================================
-- EcoLocație - Traduceri în engleză
-- Migrare: adaugă coloane _en și populează traducerile
-- ============================================

USE ecolocatie;

-- ============================================
-- PASUL 1: ALTER TABLE — coloane noi _en
-- ============================================

-- plants: adaugă description_en, habitat_en, harvest_period_en, preparation_en
ALTER TABLE plants
  ADD COLUMN description_en    TEXT          AFTER description,
  ADD COLUMN habitat_en        TEXT          AFTER habitat,
  ADD COLUMN harvest_period_en VARCHAR(150)  AFTER harvest_period,
  ADD COLUMN preparation_en    TEXT          AFTER preparation;

-- plant_usable_parts: adaugă part_en
ALTER TABLE plant_usable_parts
  ADD COLUMN part_en VARCHAR(100) AFTER part;

-- plant_benefits: adaugă benefit_en
ALTER TABLE plant_benefits
  ADD COLUMN benefit_en VARCHAR(255) AFTER benefit;

-- plant_contraindications: adaugă contraindication_en
ALTER TABLE plant_contraindications
  ADD COLUMN contraindication_en VARCHAR(255) AFTER contraindication;

-- ============================================
-- PASUL 2: UPDATE plants — traduceri engleză
-- ============================================

-- 1. Aloe Vera
UPDATE plants SET
  description_en    = 'Succulent plant native to the Arabian Peninsula, widely cultivated for its medicinal and cosmetic properties. The leaf gel is rich in vitamins, minerals, and amino acids.',
  habitat_en        = 'Cultivated in pots or greenhouses; does not tolerate frost',
  harvest_period_en = 'Year-round (cultivated)',
  preparation_en    = 'Cut the leaf and extract the transparent gel. Can be applied directly on skin or consumed in smoothies (max 2 tablespoons/day).'
WHERE id = 1;

-- 2. Brusture
UPDATE plants SET
  description_en    = 'Biennial plant widespread throughout Romania, growing along roadsides and uncultivated areas. The root has been used for centuries in traditional Romanian medicine.',
  habitat_en        = 'Roadsides, uncultivated land, ruderal areas',
  harvest_period_en = 'September - October (root, year I)',
  preparation_en    = 'Root decoction: boil 2-3 tablespoons of dried root in 500ml water for 15 minutes. Drink 2-3 cups per day.'
WHERE id = 2;

-- 3. Coada șoricelului
UPDATE plants SET
  description_en    = 'Very common perennial plant in Romania, growing in meadows and along roadsides. The Latin name comes from Achilles, who allegedly used it for wound healing.',
  habitat_en        = 'Meadows, roadsides, pastures, clearings',
  harvest_period_en = 'June - September',
  preparation_en    = 'Infusion: 1-2 teaspoons of dried plant per 250ml boiling water, steep for 10 minutes. Drink 2-3 cups per day.'
WHERE id = 3;

-- 4. Colții babei
UPDATE plants SET
  description_en    = 'Annual plant that grows on sandy and dry terrain in southern Romania. The fruits have characteristic sharp spines.',
  habitat_en        = 'Sandy, dry terrain, roadsides in the southern part of the country',
  harvest_period_en = 'August - October',
  preparation_en    = 'Infusion: 1 teaspoon of crushed fruits per 250ml boiling water, steep for 15 minutes. Drink 2 cups per day.'
WHERE id = 4;

-- 5. Floarea soarelui
UPDATE plants SET
  description_en    = 'Imposing annual plant, widely cultivated in Galați county. Seeds are rich in vitamin E, selenium, and unsaturated fatty acids.',
  habitat_en        = 'Cultivated in fields; spontaneous on ruderal terrain',
  harvest_period_en = 'September - October (seeds)',
  preparation_en    = 'Seeds are consumed raw or lightly roasted. Cold-pressed oil is used in cooking. Petal infusion: 2 tablespoons per 500ml water.'
WHERE id = 5;

-- 6. Gălbenele
UPDATE plants SET
  description_en    = 'Annual plant frequently cultivated in Romanian gardens, both ornamentally and medicinally. The flowers have an intense orange color.',
  habitat_en        = 'Gardens, crops; rarely spontaneous',
  harvest_period_en = 'June - October',
  preparation_en    = 'Infusion: 1-2 teaspoons of dried petals per 250ml boiling water, steep for 10 minutes. External: petal ointment with lard.'
WHERE id = 6;

-- 7. Hibiscus
UPDATE plants SET
  description_en    = 'Tropical plant whose flowers are used for aromatic and medicinal teas. The tea has a sour taste and intense red color.',
  habitat_en        = 'Cultivated in tropical areas; in Romania only in greenhouses or pots',
  harvest_period_en = 'Year-round (dried import)',
  preparation_en    = 'Infusion: 2 teaspoons of dried flowers per 250ml boiling water, steep for 5-10 minutes. Can be drunk hot or cold.'
WHERE id = 7;

-- 8. Iasomie
UPDATE plants SET
  description_en    = 'Climbing plant with strongly fragrant white flowers, cultivated in gardens in southern Romania. Has calming and antidepressant properties.',
  habitat_en        = 'Gardens, cultivated on supports; prefers sunny and sheltered areas',
  harvest_period_en = 'June - September',
  preparation_en    = 'Infusion: 1 teaspoon of dried flowers per 250ml boiling water, steep for 5 minutes. Drink 2 cups per day, in the evening.'
WHERE id = 8;

-- 9. Lavandă
UPDATE plants SET
  description_en    = 'Perennial aromatic plant, cultivated in Romania for essential oil. Lavender fields in Galați county are increasingly popular.',
  habitat_en        = 'Cultivated on sunny hills, calcareous soil',
  harvest_period_en = 'June - August',
  preparation_en    = 'Infusion: 1-2 teaspoons of dried flowers per 250ml boiling water, steep for 10 minutes. Essential oil: 2-3 drops in diffuser.'
WHERE id = 9;

-- 10. Mentă
UPDATE plants SET
  description_en    = 'Perennial aromatic plant, extremely widespread in Romanian gardens. Has a strong smell and refreshing taste due to menthol.',
  habitat_en        = 'Gardens, moist areas, stream banks',
  harvest_period_en = 'June - August',
  preparation_en    = 'Infusion: 1-2 teaspoons of leaves per 250ml boiling water, steep for 5-10 minutes. Drink 3-4 cups per day.'
WHERE id = 10;

-- 11. Mușețel
UPDATE plants SET
  description_en    = 'One of the most popular medicinal plants in Romania, growing spontaneously in fields and along roadsides. Has small white flowers with a yellow center.',
  habitat_en        = 'Fields, roadsides, uncultivated terrain',
  harvest_period_en = 'May - July',
  preparation_en    = 'Infusion: 2-3 teaspoons of dried flowers per 250ml boiling water, steep covered for 10-15 minutes. Drink 3-4 cups per day.'
WHERE id = 11;

-- 12. Păpădie
UPDATE plants SET
  description_en    = 'Extremely common perennial plant in Romania, often considered a weed, but with remarkable medicinal properties. All parts of the plant are usable.',
  habitat_en        = 'Meadows, gardens, roadsides — everywhere',
  harvest_period_en = 'April - May (leaves), September - October (root)',
  preparation_en    = 'Salad from young leaves. Root decoction: 2 tablespoons per 500ml water, boil for 10 minutes. Flower syrup.'
WHERE id = 12;

-- 13. Pelin
UPDATE plants SET
  description_en    = 'Perennial plant with a very bitter taste, widespread in dry areas of Romania. One of the oldest known medicinal plants.',
  habitat_en        = 'Dry terrain, roadsides, hillsides',
  harvest_period_en = 'July - August',
  preparation_en    = 'Infusion: 1/2 teaspoon of dried plant per 250ml boiling water (CAUTION: small doses!). Drink one cup per day, maximum 2 weeks.'
WHERE id = 13;

-- 14. Rostopască
UPDATE plants SET
  description_en    = 'Perennial plant that grows near fences, walls, and shaded areas. The orange juice from the stem is traditionally used for warts.',
  habitat_en        = 'Near fences, walls, shaded and ruderal areas',
  harvest_period_en = 'May - September',
  preparation_en    = 'External: fresh juice from the stem is applied directly on warts/calluses, 2-3 times per day. Internal: only under medical supervision!'
WHERE id = 14;

-- 15. Salvie
UPDATE plants SET
  description_en    = 'Perennial aromatic plant, frequently cultivated in Romanian gardens. The Latin name "Salvia" comes from "salvare" — to heal.',
  habitat_en        = 'Gardens, cultivated; spontaneous on dry, sunny slopes',
  harvest_period_en = 'May - July',
  preparation_en    = 'Infusion: 1-2 teaspoons of dried leaves per 250ml boiling water, steep for 10 minutes. Gargling for sore throats.'
WHERE id = 15;

-- 16. Sunătoare
UPDATE plants SET
  description_en    = 'Common perennial plant in Romania, growing on hills, meadows, and forest edges. Has yellow flowers and leaves with translucent dots.',
  habitat_en        = 'Hills, meadows, forest edges, dry terrain',
  harvest_period_en = 'June - August',
  preparation_en    = 'Infusion: 2 teaspoons of dried plant per 250ml boiling water, steep for 10 minutes. Oil: fresh flowers macerated in olive oil for 40 days in the sun.'
WHERE id = 16;

-- 17. Trandafir
UPDATE plants SET
  description_en    = 'Shrub cultivated in Romanian gardens, with fragrant flowers used in cosmetics and medicine. Petals are rich in vitamin C.',
  habitat_en        = 'Gardens, cultivated; spontaneous at forest edges (rosehip)',
  harvest_period_en = 'May - June (petals), September - October (rosehips)',
  preparation_en    = 'Petal infusion: 2 tablespoons per 250ml boiling water, steep for 10 minutes. Rose syrup. Rose water (distillate).'
WHERE id = 17;

-- 18. Urzică
UPDATE plants SET
  description_en    = 'Very common perennial plant in Romania, growing in moist and fertile areas. Although it stings on contact, it is extremely nutritious and medicinal.',
  habitat_en        = 'Moist, fertile areas, forest edges, gardens',
  harvest_period_en = 'April - May (young leaves), September (root)',
  preparation_en    = 'Infusion: 2-3 teaspoons of dried leaves per 250ml boiling water, steep for 10-15 minutes. Nettle soup from young leaves.'
WHERE id = 18;

-- 19. Valeriană
UPDATE plants SET
  description_en    = 'Perennial plant growing in moist areas of Romania. The root has a strong smell and has been used as a natural sedative for centuries.',
  habitat_en        = 'Moist areas, mountain meadows, stream banks',
  harvest_period_en = 'September - October (root, year II)',
  preparation_en    = 'Root infusion: 1 teaspoon of chopped root per 250ml boiling water, steep for 15 minutes. Drink in the evening, 30 min before bedtime.'
WHERE id = 19;

-- ============================================
-- PASUL 3: UPDATE plant_usable_parts — traduceri engleză
-- ============================================

-- 1. Aloe Vera
UPDATE plant_usable_parts SET part_en = 'Gel from inside the leaves' WHERE plant_id = 1 AND part = 'Gelul din interiorul frunzelor';
UPDATE plant_usable_parts SET part_en = 'Leaf juice' WHERE plant_id = 1 AND part = 'Sucul frunzelor';

-- 2. Brusture
UPDATE plant_usable_parts SET part_en = 'Root' WHERE plant_id = 2 AND part = 'Rădăcina';
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 2 AND part = 'Frunzele tinere';
UPDATE plant_usable_parts SET part_en = 'Seeds' WHERE plant_id = 2 AND part = 'Semințele';

-- 3. Coada șoricelului
UPDATE plant_usable_parts SET part_en = 'Stems' WHERE plant_id = 3 AND part = 'Tulpini';
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 3 AND part = 'Frunze';
UPDATE plant_usable_parts SET part_en = 'Flowers' WHERE plant_id = 3 AND part = 'Flori';

-- 4. Colții babei
UPDATE plant_usable_parts SET part_en = 'Fruits' WHERE plant_id = 4 AND part = 'Fructele';
UPDATE plant_usable_parts SET part_en = 'Aerial parts' WHERE plant_id = 4 AND part = 'Părțile aeriene';

-- 5. Floarea soarelui
UPDATE plant_usable_parts SET part_en = 'Seeds' WHERE plant_id = 5 AND part = 'Semințele';
UPDATE plant_usable_parts SET part_en = 'Petals' WHERE plant_id = 5 AND part = 'Petalele';
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 5 AND part = 'Frunzele tinere';

-- 6. Gălbenele
UPDATE plant_usable_parts SET part_en = 'Flowers (petals)' WHERE plant_id = 6 AND part = 'Florile (petalele)';
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 6 AND part = 'Frunzele tinere';

-- 7. Hibiscus
UPDATE plant_usable_parts SET part_en = 'Flowers (calyx and petals)' WHERE plant_id = 7 AND part = 'Florile (caliciul și petalele)';
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 7 AND part = 'Frunzele tinere';

-- 8. Iasomie
UPDATE plant_usable_parts SET part_en = 'Flowers' WHERE plant_id = 8 AND part = 'Florile';
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 8 AND part = 'Frunzele';

-- 9. Lavandă
UPDATE plant_usable_parts SET part_en = 'Flowers' WHERE plant_id = 9 AND part = 'Florile';
UPDATE plant_usable_parts SET part_en = 'Young flowering stems' WHERE plant_id = 9 AND part = 'Tulpinile tinere cu flori';

-- 10. Mentă
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 10 AND part = 'Frunzele';
UPDATE plant_usable_parts SET part_en = 'Young stems' WHERE plant_id = 10 AND part = 'Tulpinile tinere';

-- 11. Mușețel
UPDATE plant_usable_parts SET part_en = 'Flowers (flower heads)' WHERE plant_id = 11 AND part = 'Florile (capitulele florale)';

-- 12. Păpădie
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 12 AND part = 'Frunzele';
UPDATE plant_usable_parts SET part_en = 'Root' WHERE plant_id = 12 AND part = 'Rădăcina';
UPDATE plant_usable_parts SET part_en = 'Flowers' WHERE plant_id = 12 AND part = 'Florile';
UPDATE plant_usable_parts SET part_en = 'Stem' WHERE plant_id = 12 AND part = 'Tulpina';

-- 13. Pelin
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 13 AND part = 'Frunzele';
UPDATE plant_usable_parts SET part_en = 'Flowering tops' WHERE plant_id = 13 AND part = 'Vârfurile florale';

-- 14. Rostopască
UPDATE plant_usable_parts SET part_en = 'Stem (juice)' WHERE plant_id = 14 AND part = 'Tulpina (sucul)';
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 14 AND part = 'Frunzele';
UPDATE plant_usable_parts SET part_en = 'Root' WHERE plant_id = 14 AND part = 'Rădăcina';

-- 15. Salvie
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 15 AND part = 'Frunzele';

-- 16. Sunătoare
UPDATE plant_usable_parts SET part_en = 'Flowers' WHERE plant_id = 16 AND part = 'Florile';
UPDATE plant_usable_parts SET part_en = 'Leaves' WHERE plant_id = 16 AND part = 'Frunzele';
UPDATE plant_usable_parts SET part_en = 'Thin stems' WHERE plant_id = 16 AND part = 'Tulpinile subțiri';

-- 17. Trandafir
UPDATE plant_usable_parts SET part_en = 'Petals' WHERE plant_id = 17 AND part = 'Petalele';
UPDATE plant_usable_parts SET part_en = 'Fruits (rosehips)' WHERE plant_id = 17 AND part = 'Fructele (măceșele)';
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 17 AND part = 'Frunzele tinere';

-- 18. Urzică
UPDATE plant_usable_parts SET part_en = 'Young leaves' WHERE plant_id = 18 AND part = 'Frunzele tinere';
UPDATE plant_usable_parts SET part_en = 'Root' WHERE plant_id = 18 AND part = 'Rădăcina';
UPDATE plant_usable_parts SET part_en = 'Seeds' WHERE plant_id = 18 AND part = 'Semințele';

-- 19. Valeriană
UPDATE plant_usable_parts SET part_en = 'Root' WHERE plant_id = 19 AND part = 'Rădăcina';
UPDATE plant_usable_parts SET part_en = 'Rhizome' WHERE plant_id = 19 AND part = 'Rizomul';

-- ============================================
-- PASUL 4: UPDATE plant_benefits — traduceri engleză
-- ============================================

-- 1. Aloe Vera
UPDATE plant_benefits SET benefit_en = 'Hydrates and regenerates the skin' WHERE plant_id = 1 AND benefit = 'Hidratează și regenerează pielea';
UPDATE plant_benefits SET benefit_en = 'Heals burns and superficial wounds' WHERE plant_id = 1 AND benefit = 'Vindecă arsurile și rănile superficiale';
UPDATE plant_benefits SET benefit_en = 'Soothes skin irritations and eczema' WHERE plant_id = 1 AND benefit = 'Calmează iritațiile pielii și eczemele';
UPDATE plant_benefits SET benefit_en = 'Supports digestion and relieves constipation' WHERE plant_id = 1 AND benefit = 'Susține digestia și ameliorează constipația';
UPDATE plant_benefits SET benefit_en = 'Has anti-inflammatory properties' WHERE plant_id = 1 AND benefit = 'Are proprietăți antiinflamatorii';

-- 2. Brusture
UPDATE plant_benefits SET benefit_en = 'Purifies the blood and eliminates toxins' WHERE plant_id = 2 AND benefit = 'Purifică sângele și elimină toxinele';
UPDATE plant_benefits SET benefit_en = 'Treats skin conditions (acne, eczema, psoriasis)' WHERE plant_id = 2 AND benefit = 'Tratează afecțiunile pielii (acnee, eczeme, psoriazis)';
UPDATE plant_benefits SET benefit_en = 'Stimulates liver function' WHERE plant_id = 2 AND benefit = 'Stimulează funcția ficatului';
UPDATE plant_benefits SET benefit_en = 'Has natural diuretic effect' WHERE plant_id = 2 AND benefit = 'Are efect diuretic natural';
UPDATE plant_benefits SET benefit_en = 'Regulates blood sugar levels' WHERE plant_id = 2 AND benefit = 'Reglează glicemia';

-- 3. Coada șoricelului
UPDATE plant_benefits SET benefit_en = 'Stops bleeding and heals wounds' WHERE plant_id = 3 AND benefit = 'Oprește hemoragiile și vindecă rănile';
UPDATE plant_benefits SET benefit_en = 'Relieves menstrual pain' WHERE plant_id = 3 AND benefit = 'Ameliorează durerile menstruale';
UPDATE plant_benefits SET benefit_en = 'Improves digestion' WHERE plant_id = 3 AND benefit = 'Îmbunătățește digestia';
UPDATE plant_benefits SET benefit_en = 'Has anti-inflammatory properties' WHERE plant_id = 3 AND benefit = 'Are proprietăți antiinflamatorii';
UPDATE plant_benefits SET benefit_en = 'Reduces fever' WHERE plant_id = 3 AND benefit = 'Reduce febra';

-- 4. Colții babei
UPDATE plant_benefits SET benefit_en = 'Naturally increases testosterone levels' WHERE plant_id = 4 AND benefit = 'Crește nivelul de testosteron natural';
UPDATE plant_benefits SET benefit_en = 'Improves libido and fertility' WHERE plant_id = 4 AND benefit = 'Îmbunătățește libidoul și fertilitatea';
UPDATE plant_benefits SET benefit_en = 'Supports urinary tract health' WHERE plant_id = 4 AND benefit = 'Susține sănătatea tractului urinar';
UPDATE plant_benefits SET benefit_en = 'Has tonic and energizing effect' WHERE plant_id = 4 AND benefit = 'Are efect tonic și energizant';
UPDATE plant_benefits SET benefit_en = 'Supports cardiovascular health' WHERE plant_id = 4 AND benefit = 'Susține sănătatea cardiovasculară';

-- 5. Floarea soarelui
UPDATE plant_benefits SET benefit_en = 'Rich in vitamin E (powerful antioxidant)' WHERE plant_id = 5 AND benefit = 'Bogată în vitamina E (antioxidant puternic)';
UPDATE plant_benefits SET benefit_en = 'Reduces bad cholesterol (LDL)' WHERE plant_id = 5 AND benefit = 'Reduce colesterolul rău (LDL)';
UPDATE plant_benefits SET benefit_en = 'Supports cardiovascular health' WHERE plant_id = 5 AND benefit = 'Susține sănătatea cardiovasculară';
UPDATE plant_benefits SET benefit_en = 'Strengthens the immune system' WHERE plant_id = 5 AND benefit = 'Întărește sistemul imunitar';
UPDATE plant_benefits SET benefit_en = 'Has anti-inflammatory effect' WHERE plant_id = 5 AND benefit = 'Are efect antiinflamator';

-- 6. Gălbenele
UPDATE plant_benefits SET benefit_en = 'Heals wounds and burns (external)' WHERE plant_id = 6 AND benefit = 'Vindecă rănile și arsurile (extern)';
UPDATE plant_benefits SET benefit_en = 'Has antifungal and antibacterial properties' WHERE plant_id = 6 AND benefit = 'Are proprietăți antifungice și antibacteriene';
UPDATE plant_benefits SET benefit_en = 'Soothes skin inflammations' WHERE plant_id = 6 AND benefit = 'Calmează inflamațiile pielii';
UPDATE plant_benefits SET benefit_en = 'Relieves gastric ulcer' WHERE plant_id = 6 AND benefit = 'Ameliorează ulcerul gastric';
UPDATE plant_benefits SET benefit_en = 'Regulates menstrual cycle' WHERE plant_id = 6 AND benefit = 'Reglează ciclul menstrual';

-- 7. Hibiscus
UPDATE plant_benefits SET benefit_en = 'Lowers blood pressure' WHERE plant_id = 7 AND benefit = 'Scade tensiunea arterială';
UPDATE plant_benefits SET benefit_en = 'Rich in vitamin C and antioxidants' WHERE plant_id = 7 AND benefit = 'Bogat în vitamina C și antioxidanți';
UPDATE plant_benefits SET benefit_en = 'Reduces cholesterol' WHERE plant_id = 7 AND benefit = 'Reduce colesterolul';
UPDATE plant_benefits SET benefit_en = 'Supports liver health' WHERE plant_id = 7 AND benefit = 'Susține sănătatea ficatului';
UPDATE plant_benefits SET benefit_en = 'Aids weight loss (boosts metabolism)' WHERE plant_id = 7 AND benefit = 'Ajută la slăbit (accelerează metabolismul)';

-- 8. Iasomie
UPDATE plant_benefits SET benefit_en = 'Reduces stress and anxiety' WHERE plant_id = 8 AND benefit = 'Reduce stresul și anxietatea';
UPDATE plant_benefits SET benefit_en = 'Improves sleep quality' WHERE plant_id = 8 AND benefit = 'Îmbunătățește calitatea somnului';
UPDATE plant_benefits SET benefit_en = 'Has natural antidepressant effect' WHERE plant_id = 8 AND benefit = 'Are efect antidepresiv natural';
UPDATE plant_benefits SET benefit_en = 'Soothes headaches' WHERE plant_id = 8 AND benefit = 'Calmează durerile de cap';
UPDATE plant_benefits SET benefit_en = 'Has antiseptic properties' WHERE plant_id = 8 AND benefit = 'Are proprietăți antiseptice';

-- 9. Lavandă
UPDATE plant_benefits SET benefit_en = 'Reduces anxiety and stress' WHERE plant_id = 9 AND benefit = 'Reduce anxietatea și stresul';
UPDATE plant_benefits SET benefit_en = 'Improves sleep' WHERE plant_id = 9 AND benefit = 'Îmbunătățește somnul';
UPDATE plant_benefits SET benefit_en = 'Soothes headaches and migraines' WHERE plant_id = 9 AND benefit = 'Calmează durerile de cap și migrenele';
UPDATE plant_benefits SET benefit_en = 'Has antiseptic and wound-healing effect' WHERE plant_id = 9 AND benefit = 'Are efect antiseptic și cicatrizant';
UPDATE plant_benefits SET benefit_en = 'Relaxes muscles and reduces tension' WHERE plant_id = 9 AND benefit = 'Relaxează mușchii și reduce tensiunea';

-- 10. Mentă
UPDATE plant_benefits SET benefit_en = 'Relieves digestive disorders' WHERE plant_id = 10 AND benefit = 'Ameliorează tulburările digestive';
UPDATE plant_benefits SET benefit_en = 'Soothes nausea and vomiting' WHERE plant_id = 10 AND benefit = 'Calmează greața și vărsăturile';
UPDATE plant_benefits SET benefit_en = 'Reduces headaches' WHERE plant_id = 10 AND benefit = 'Reduce durerile de cap';
UPDATE plant_benefits SET benefit_en = 'Decongests the respiratory tract' WHERE plant_id = 10 AND benefit = 'Descongestionează căile respiratorii';
UPDATE plant_benefits SET benefit_en = 'Has cooling and invigorating effect' WHERE plant_id = 10 AND benefit = 'Are efect răcoritor și revigorant';

-- 11. Mușețel
UPDATE plant_benefits SET benefit_en = 'Calms nerves and reduces anxiety' WHERE plant_id = 11 AND benefit = 'Calmează nervii și reduce anxietatea';
UPDATE plant_benefits SET benefit_en = 'Improves sleep' WHERE plant_id = 11 AND benefit = 'Îmbunătățește somnul';
UPDATE plant_benefits SET benefit_en = 'Relieves colic and abdominal pain' WHERE plant_id = 11 AND benefit = 'Ameliorează colicile și durerile abdominale';
UPDATE plant_benefits SET benefit_en = 'Has anti-inflammatory effect (internal and external)' WHERE plant_id = 11 AND benefit = 'Are efect antiinflamator (intern și extern)';
UPDATE plant_benefits SET benefit_en = 'Treats eye inflammations (compresses)' WHERE plant_id = 11 AND benefit = 'Tratează inflamațiile oculare (comprese)';

-- 12. Păpădie
UPDATE plant_benefits SET benefit_en = 'Stimulates liver and gallbladder function' WHERE plant_id = 12 AND benefit = 'Stimulează funcția ficatului și a vezicii biliare';
UPDATE plant_benefits SET benefit_en = 'Has powerful diuretic effect' WHERE plant_id = 12 AND benefit = 'Are efect diuretic puternic';
UPDATE plant_benefits SET benefit_en = 'Rich in vitamins (A, C, K) and minerals' WHERE plant_id = 12 AND benefit = 'Bogată în vitamine (A, C, K) și minerale';
UPDATE plant_benefits SET benefit_en = 'Aids body detoxification' WHERE plant_id = 12 AND benefit = 'Ajută la detoxifierea organismului';
UPDATE plant_benefits SET benefit_en = 'Regulates digestion' WHERE plant_id = 12 AND benefit = 'Reglează digestia';

-- 13. Pelin
UPDATE plant_benefits SET benefit_en = 'Stimulates appetite and digestion' WHERE plant_id = 13 AND benefit = 'Stimulează apetitul și digestia';
UPDATE plant_benefits SET benefit_en = 'Has antiparasitic effect (intestinal worms)' WHERE plant_id = 13 AND benefit = 'Are efect antiparazitar (viermi intestinali)';
UPDATE plant_benefits SET benefit_en = 'Relieves stomach pain' WHERE plant_id = 13 AND benefit = 'Ameliorează durerile de stomac';
UPDATE plant_benefits SET benefit_en = 'Has anti-inflammatory properties' WHERE plant_id = 13 AND benefit = 'Are proprietăți antiinflamatorii';
UPDATE plant_benefits SET benefit_en = 'Treats biliary conditions' WHERE plant_id = 13 AND benefit = 'Tratează afecțiunile biliare';

-- 14. Rostopască
UPDATE plant_benefits SET benefit_en = 'Treats warts and calluses (external, stem juice)' WHERE plant_id = 14 AND benefit = 'Tratează negii și bătăturile (extern, suc din tulpină)';
UPDATE plant_benefits SET benefit_en = 'Supports liver health' WHERE plant_id = 14 AND benefit = 'Susține sănătatea ficatului';
UPDATE plant_benefits SET benefit_en = 'Has antispasmodic properties' WHERE plant_id = 14 AND benefit = 'Are proprietăți antispastice';
UPDATE plant_benefits SET benefit_en = 'Stimulates bile secretion' WHERE plant_id = 14 AND benefit = 'Stimulează secreția biliară';
UPDATE plant_benefits SET benefit_en = 'Has antimicrobial effect' WHERE plant_id = 14 AND benefit = 'Are efect antimicrobian';

-- 15. Salvie
UPDATE plant_benefits SET benefit_en = 'Treats sore throat and oral inflammations' WHERE plant_id = 15 AND benefit = 'Tratează durerile de gât și inflamațiile bucale';
UPDATE plant_benefits SET benefit_en = 'Reduces excessive sweating' WHERE plant_id = 15 AND benefit = 'Reduce transpirația excesivă';
UPDATE plant_benefits SET benefit_en = 'Relieves menopause symptoms' WHERE plant_id = 15 AND benefit = 'Ameliorează simptomele menopauzei';
UPDATE plant_benefits SET benefit_en = 'Improves memory and concentration' WHERE plant_id = 15 AND benefit = 'Îmbunătățește memoria și concentrarea';
UPDATE plant_benefits SET benefit_en = 'Has antibacterial properties' WHERE plant_id = 15 AND benefit = 'Are proprietăți antibacteriene';

-- 16. Sunătoare
UPDATE plant_benefits SET benefit_en = 'Treats mild to moderate depression' WHERE plant_id = 16 AND benefit = 'Tratează depresia ușoară și moderată';
UPDATE plant_benefits SET benefit_en = 'Reduces anxiety and insomnia' WHERE plant_id = 16 AND benefit = 'Reduce anxietatea și insomnia';
UPDATE plant_benefits SET benefit_en = 'Heals wounds and burns (St. John''s Wort oil)' WHERE plant_id = 16 AND benefit = 'Vindecă rănile și arsurile (uleiul de sunătoare)';
UPDATE plant_benefits SET benefit_en = 'Has antiviral effect' WHERE plant_id = 16 AND benefit = 'Are efect antiviral';
UPDATE plant_benefits SET benefit_en = 'Relieves neuralgic pain' WHERE plant_id = 16 AND benefit = 'Ameliorează durerile nevralgice';

-- 17. Trandafir
UPDATE plant_benefits SET benefit_en = 'Rich in vitamin C (especially rosehips)' WHERE plant_id = 17 AND benefit = 'Bogat în vitamina C (mai ales măceșele)';
UPDATE plant_benefits SET benefit_en = 'Tones and hydrates the skin' WHERE plant_id = 17 AND benefit = 'Tonifică și hidratează pielea';
UPDATE plant_benefits SET benefit_en = 'Reduces stress and anxiety (aromatherapy)' WHERE plant_id = 17 AND benefit = 'Reduce stresul și anxietatea (aromaterapie)';
UPDATE plant_benefits SET benefit_en = 'Has mild laxative effect' WHERE plant_id = 17 AND benefit = 'Are efect ușor laxativ';
UPDATE plant_benefits SET benefit_en = 'Strengthens the immune system' WHERE plant_id = 17 AND benefit = 'Întărește sistemul imunitar';

-- 18. Urzică
UPDATE plant_benefits SET benefit_en = 'Fights anemia (rich in iron)' WHERE plant_id = 18 AND benefit = 'Combate anemia (bogată în fier)';
UPDATE plant_benefits SET benefit_en = 'Has powerful anti-inflammatory effect' WHERE plant_id = 18 AND benefit = 'Are efect antiinflamator puternic';
UPDATE plant_benefits SET benefit_en = 'Treats rheumatic conditions' WHERE plant_id = 18 AND benefit = 'Tratează afecțiunile reumatice';
UPDATE plant_benefits SET benefit_en = 'Purifies the blood and detoxifies the body' WHERE plant_id = 18 AND benefit = 'Purifică sângele și detoxifică organismul';
UPDATE plant_benefits SET benefit_en = 'Stimulates hair growth' WHERE plant_id = 18 AND benefit = 'Stimulează creșterea părului';

-- 19. Valeriană
UPDATE plant_benefits SET benefit_en = 'Fights insomnia (natural sedative)' WHERE plant_id = 19 AND benefit = 'Combate insomnia (sedativ natural)';
UPDATE plant_benefits SET benefit_en = 'Reduces anxiety and stress' WHERE plant_id = 19 AND benefit = 'Reduce anxietatea și stresul';
UPDATE plant_benefits SET benefit_en = 'Relaxes muscles and reduces cramps' WHERE plant_id = 19 AND benefit = 'Relaxează mușchii și reduce crampele';
UPDATE plant_benefits SET benefit_en = 'Relieves tension headaches' WHERE plant_id = 19 AND benefit = 'Ameliorează durerile de cap de tensiune';
UPDATE plant_benefits SET benefit_en = 'Calms heart palpitations' WHERE plant_id = 19 AND benefit = 'Calmează palpitațiile cardiace';

-- ============================================
-- PASUL 5: UPDATE plant_contraindications — traduceri engleză
-- ============================================

-- 1. Aloe Vera
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated during pregnancy (may cause contractions)' WHERE plant_id = 1 AND contraindication = 'Contraindicat în sarcină (poate provoca contracții)';
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered internally to children under 12' WHERE plant_id = 1 AND contraindication = 'Nu se administrează intern copiilor sub 12 ani';
UPDATE plant_contraindications SET contraindication_en = 'May interact with diabetes medications' WHERE plant_id = 1 AND contraindication = 'Poate interacționa cu medicamente pentru diabet';

-- 2. Brusture
UPDATE plant_contraindications SET contraindication_en = 'Avoid during pregnancy and breastfeeding' WHERE plant_id = 2 AND contraindication = 'Evitați în sarcină și alăptare';
UPDATE plant_contraindications SET contraindication_en = 'May interact with anticoagulants' WHERE plant_id = 2 AND contraindication = 'Poate interacționa cu anticoagulantele';
UPDATE plant_contraindications SET contraindication_en = 'People allergic to Asteraceae family plants' WHERE plant_id = 2 AND contraindication = 'Persoanele alergice la plante din familia Asteraceae';

-- 3. Coada șoricelului
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated during pregnancy' WHERE plant_id = 3 AND contraindication = 'Contraindicată în sarcină';
UPDATE plant_contraindications SET contraindication_en = 'Do not use in case of allergy to Asteraceae family plants' WHERE plant_id = 3 AND contraindication = 'Nu se folosește în caz de alergie la plante din familia Asteraceae';
UPDATE plant_contraindications SET contraindication_en = 'May interact with anticoagulants' WHERE plant_id = 3 AND contraindication = 'Poate interacționa cu anticoagulantele';

-- 4. Colții babei
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered during pregnancy and breastfeeding' WHERE plant_id = 4 AND contraindication = 'Nu se administrează în sarcină și alăptare';
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated for people with hormonal problems' WHERE plant_id = 4 AND contraindication = 'Contraindicat persoanelor cu probleme hormonale';
UPDATE plant_contraindications SET contraindication_en = 'May interact with diabetes and blood pressure medications' WHERE plant_id = 4 AND contraindication = 'Poate interacționa cu medicamente pentru diabet și tensiune';

-- 5. Floarea soarelui
UPDATE plant_contraindications SET contraindication_en = 'Allergy to Asteraceae family plants' WHERE plant_id = 5 AND contraindication = 'Alergii la plante din familia Asteraceae';
UPDATE plant_contraindications SET contraindication_en = 'Excessive seed consumption may increase caloric intake' WHERE plant_id = 5 AND contraindication = 'Consumul excesiv de semințe poate crește aportul caloric';
UPDATE plant_contraindications SET contraindication_en = 'Salted seeds are contraindicated in hypertension' WHERE plant_id = 5 AND contraindication = 'Semințele sărate sunt contraindicate în hipertensiune';

-- 6. Gălbenele
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated during pregnancy' WHERE plant_id = 6 AND contraindication = 'Contraindicată în sarcină';
UPDATE plant_contraindications SET contraindication_en = 'Allergy to Asteraceae family plants' WHERE plant_id = 6 AND contraindication = 'Alergie la plante din familia Asteraceae';
UPDATE plant_contraindications SET contraindication_en = 'May interact with sedatives' WHERE plant_id = 6 AND contraindication = 'Poate interacționa cu sedativele';

-- 7. Hibiscus
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated for people with low blood pressure' WHERE plant_id = 7 AND contraindication = 'Contraindicat persoanelor cu tensiune scăzută';
UPDATE plant_contraindications SET contraindication_en = 'Not to be consumed during pregnancy (may induce contractions)' WHERE plant_id = 7 AND contraindication = 'Nu se consumă în sarcină (poate induce contracții)';
UPDATE plant_contraindications SET contraindication_en = 'May interact with antihypertensive medications' WHERE plant_id = 7 AND contraindication = 'Poate interacționa cu medicamentele antihipertensive';

-- 8. Iasomie
UPDATE plant_contraindications SET contraindication_en = 'Avoid during pregnancy (first months)' WHERE plant_id = 8 AND contraindication = 'Evitați în sarcină (primele luni)';
UPDATE plant_contraindications SET contraindication_en = 'Excessive consumption may cause headaches' WHERE plant_id = 8 AND contraindication = 'Consumul excesiv poate provoca dureri de cap';
UPDATE plant_contraindications SET contraindication_en = 'May cause allergic reactions in sensitive people' WHERE plant_id = 8 AND contraindication = 'Poate provoca reacții alergice la persoanele sensibile';

-- 9. Lavandă
UPDATE plant_contraindications SET contraindication_en = 'Do not apply undiluted essential oil on skin' WHERE plant_id = 9 AND contraindication = 'Nu se aplică ulei esențial nediluat pe piele';
UPDATE plant_contraindications SET contraindication_en = 'Avoid during pregnancy (first months)' WHERE plant_id = 9 AND contraindication = 'Evitați în sarcină (primele luni)';
UPDATE plant_contraindications SET contraindication_en = 'May cause drowsiness (do not drive after consumption)' WHERE plant_id = 9 AND contraindication = 'Poate provoca somnolență (nu conduceți după consum)';

-- 10. Mentă
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated in gastroesophageal reflux' WHERE plant_id = 10 AND contraindication = 'Contraindicată în reflux gastroesofagian';
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered to children under 3 years' WHERE plant_id = 10 AND contraindication = 'Nu se administrează copiilor sub 3 ani';
UPDATE plant_contraindications SET contraindication_en = 'May reduce breast milk production' WHERE plant_id = 10 AND contraindication = 'Poate reduce producția de lapte matern';

-- 11. Mușețel
UPDATE plant_contraindications SET contraindication_en = 'Allergy to Asteraceae family plants' WHERE plant_id = 11 AND contraindication = 'Alergie la plante din familia Asteraceae';
UPDATE plant_contraindications SET contraindication_en = 'May interact with anticoagulants' WHERE plant_id = 11 AND contraindication = 'Poate interacționa cu anticoagulantele';
UPDATE plant_contraindications SET contraindication_en = 'Excessive consumption may cause vomiting' WHERE plant_id = 11 AND contraindication = 'Consumul excesiv poate provoca vărsături';

-- 12. Păpădie
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated for people with gallstones' WHERE plant_id = 12 AND contraindication = 'Contraindicată persoanelor cu calculi biliari';
UPDATE plant_contraindications SET contraindication_en = 'May interact with diuretics and anticoagulants' WHERE plant_id = 12 AND contraindication = 'Poate interacționa cu diureticele și anticoagulantele';
UPDATE plant_contraindications SET contraindication_en = 'May cause allergic reactions' WHERE plant_id = 12 AND contraindication = 'Poate provoca reacții alergice';

-- 13. Pelin
UPDATE plant_contraindications SET contraindication_en = 'TOXIC in large doses! Strictly follow dosage' WHERE plant_id = 13 AND contraindication = 'TOXIC în doze mari! Se respectă strict dozajul';
UPDATE plant_contraindications SET contraindication_en = 'Absolutely contraindicated during pregnancy' WHERE plant_id = 13 AND contraindication = 'Absolut contraindicat în sarcină';
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered to children' WHERE plant_id = 13 AND contraindication = 'Nu se administrează copiilor';
UPDATE plant_contraindications SET contraindication_en = 'Do not use for more than 2 consecutive weeks' WHERE plant_id = 13 AND contraindication = 'Nu se folosește mai mult de 2 săptămâni consecutiv';

-- 14. Rostopască
UPDATE plant_contraindications SET contraindication_en = 'Juice is TOXIC internally in large doses' WHERE plant_id = 14 AND contraindication = 'Sucul este TOXIC intern în doze mari';
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated during pregnancy and breastfeeding' WHERE plant_id = 14 AND contraindication = 'Contraindicată în sarcină și alăptare';
UPDATE plant_contraindications SET contraindication_en = 'May cause skin irritation upon application' WHERE plant_id = 14 AND contraindication = 'Poate provoca iritații ale pielii la aplicare';
UPDATE plant_contraindications SET contraindication_en = 'Internal use only under medical supervision' WHERE plant_id = 14 AND contraindication = 'Uz intern doar sub supraveghere medicală';

-- 15. Salvie
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated during pregnancy and breastfeeding' WHERE plant_id = 15 AND contraindication = 'Contraindicată în sarcină și alăptare';
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered to people with epilepsy' WHERE plant_id = 15 AND contraindication = 'Nu se administrează persoanelor cu epilepsie';
UPDATE plant_contraindications SET contraindication_en = 'Excessive consumption may be toxic (thujone)' WHERE plant_id = 15 AND contraindication = 'Consumul excesiv poate fi toxic (tujonă)';

-- 16. Sunătoare
UPDATE plant_contraindications SET contraindication_en = 'Interacts with MANY medications (antidepressants, contraceptives, anticoagulants)' WHERE plant_id = 16 AND contraindication = 'Interacționează cu MULTE medicamente (antidepresive, contraceptive, anticoagulante)';
UPDATE plant_contraindications SET contraindication_en = 'Causes photosensitivity (avoid sun exposure)' WHERE plant_id = 16 AND contraindication = 'Provoacă fotosensibilitate (evitați expunerea la soare)';
UPDATE plant_contraindications SET contraindication_en = 'Do not combine with other antidepressants' WHERE plant_id = 16 AND contraindication = 'Nu se asociază cu alte antidepresive';

-- 17. Trandafir
UPDATE plant_contraindications SET contraindication_en = 'People allergic to roses' WHERE plant_id = 17 AND contraindication = 'Persoanele alergice la trandafiri';
UPDATE plant_contraindications SET contraindication_en = 'Excessive rosehip consumption may cause diarrhea' WHERE plant_id = 17 AND contraindication = 'Consumul excesiv de măcese poate provoca diaree';
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated for people with kidney stones (vitamin C)' WHERE plant_id = 17 AND contraindication = 'Contraindicat persoanelor cu calculi renali (vitamina C)';

-- 18. Urzică
UPDATE plant_contraindications SET contraindication_en = 'Contraindicated for people with fluid retention caused by heart failure' WHERE plant_id = 18 AND contraindication = 'Contraindicată persoanelor cu retenție de lichide cauzată de insuficiență cardiacă';
UPDATE plant_contraindications SET contraindication_en = 'May interact with anticoagulants and antihypertensives' WHERE plant_id = 18 AND contraindication = 'Poate interacționa cu anticoagulantele și antihipertensivele';
UPDATE plant_contraindications SET contraindication_en = 'Consume only cooked or dried (fresh stings)' WHERE plant_id = 18 AND contraindication = 'Se consumă doar gătită sau uscată (proaspătă arde)';

-- 19. Valeriană
UPDATE plant_contraindications SET contraindication_en = 'Do not combine with alcohol or sedatives' WHERE plant_id = 19 AND contraindication = 'Nu se asociază cu alcoolul sau sedativele';
UPDATE plant_contraindications SET contraindication_en = 'May cause drowsiness (do not drive after consumption)' WHERE plant_id = 19 AND contraindication = 'Poate provoca somnolență (nu conduceți după consum)';
UPDATE plant_contraindications SET contraindication_en = 'Not to be administered to children under 3 years' WHERE plant_id = 19 AND contraindication = 'Nu se administrează copiilor sub 3 ani';
UPDATE plant_contraindications SET contraindication_en = 'Do not use for more than 4 consecutive weeks' WHERE plant_id = 19 AND contraindication = 'Nu se folosește mai mult de 4 săptămâni consecutiv';
