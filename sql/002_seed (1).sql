-- ============================================
-- EcoLocație - Seed complet
-- Versiunea 2.1 — aliniat cu schema finală
-- ============================================

USE ecolocatie;

-- ============================================
-- CONFIG (singleton — setări hartă Galați)
-- ============================================
INSERT INTO config (
  map_center_lat, map_center_lng,
  map_default_zoom, map_max_zoom, map_min_zoom,
  tile_url, tile_attribution,
  bounds_north, bounds_south, bounds_east, bounds_west,
  active_model
) VALUES (
  45.4353000, 28.0080000,
  13, 18, 10,
  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  '&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a> contributors',
  45.4800000, 45.3900000, 28.0800000, 27.9300000,
  'model_densenet121.h5'
);

-- ============================================
-- USERS (5 utilizatori: 1 admin + 4 useri)
-- Parolele sunt hash-uri bcrypt placeholder
-- ============================================
INSERT INTO users (id, username, first_name, last_name, email, password_hash, phone, birth_date, role, is_active, profile_image) VALUES
(1, 'admin',       'Admin',    'EcoLocație', 'admin@ecolocatie.ro',
 '$2b$10$XQxBGVHKD5y1qHRdKlEOzOKwQ8vF3Yb2xN7mD9pR4sT6uW1xZ0aBC', NULL, NULL,
 'admin', TRUE, NULL),
(2, 'maria.ion',   'Maria',    'Ion',        'maria.ion@email.com',
 '$2b$10$aB1cD2eF3gH4iJ5kL6mN7oP8qR9sT0uV1wX2yZ3aB4cD5eF6gH7i',
 '0745123456', '1995-03-15', 'user', TRUE, NULL),
(3, 'andrei.pop',  'Andrei',   'Pop',        'andrei.pop@email.com',
 '$2b$10$bC2dE3fG4hI5jK6lM7nO8pQ9rS0tU1vW2xY3zA4bC5dE6fG7hI8j',
 '0723987654', '1990-07-22', 'user', TRUE, NULL),
(4, 'elena.dumitrescu', 'Elena', 'Dumitrescu', 'elena.d@email.com',
 '$2b$10$cD3eF4gH5iJ6kL7mN8oP9qR0sT1uV2wX3yZ4aB5cD6eF7gH8iJ9k',
 NULL, '1998-11-30', 'user', TRUE, NULL),
(5, 'bogdan.stan', 'Bogdan',   'Stan',       'bogdan.stan@email.com',
 '$2b$10$dE4fG5hI6jK7lM8nO9pQ0rS1tU2vW3xY4zA5bC6dE7fG8hI9jK0l',
 '0734567890', '1988-01-10', 'user', TRUE, NULL);

-- ============================================
-- PLANTE MEDICINALE (19 plante)
-- Cu family, habitat, harvest_period, icon_color
-- ============================================
INSERT INTO plants (id, name_ro, name_latin, name_en, family, description, habitat, harvest_period, preparation, image_url, icon_color, folder_name) VALUES

(1, 'Aloe Vera', 'Aloe barbadensis', 'Aloe Vera', 'Asphodelaceae',
'Plantă suculentă originară din Peninsula Arabică, cultivată pe scară largă pentru proprietățile sale medicinale și cosmetice. Gelul din frunze este bogat în vitamine, minerale și aminoacizi.',
'Cultivată în ghivece sau sere; nu rezistă la îngheț',
'Tot anul (cultivată)',
'Se taie frunza și se extrage gelul transparent. Se poate aplica direct pe piele sau se poate consuma în smoothie-uri (max 2 linguri/zi).',
'/images/plants/aloe-vera', '#66BB6A', 'Aloe Vera'),

(2, 'Brusture', 'Arctium lappa', 'Burdock', 'Asteraceae',
'Plantă bienală răspândită în toată România, crește pe marginea drumurilor și în locuri necultivate. Rădăcina este folosită de secole în medicina tradițională românească.',
'Marginea drumurilor, terenuri necultivate, ruderale',
'Septembrie - Octombrie (rădăcina, anul I)',
'Decoct din rădăcină: se fierb 2-3 linguri de rădăcină uscată în 500ml apă timp de 15 minute. Se beau 2-3 căni pe zi.',
'/images/plants/brusture', '#8D6E63', 'Brusture'),

(3, 'Coada șoricelului', 'Achillea millefolium', 'Yarrow', 'Asteraceae',
'Plantă perenă foarte comună în România, crește în pajiști, pe marginea drumurilor. Numele latin vine de la Ahile, care ar fi folosit-o pentru vindecarea rănilor.',
'Pajiști, margini de drum, pășuni, poieni',
'Iunie - Septembrie',
'Infuzie: 1-2 lingurite de plantă uscată la 250ml apă clocotită, se lasă 10 minute. Se beau 2-3 căni pe zi.',
'/images/plants/coada-soricelului', '#FFEE58', 'Coada soricelului'),

(4, 'Colții babei', 'Tribulus terrestris', 'Puncture Vine', 'Zygophyllaceae',
'Plantă anuală care crește pe terenuri nisipoase și uscate din sudul României. Fructele au țepi ascuțiți caracteristici.',
'Terenuri nisipoase, uscate, marginea drumurilor din sudul țării',
'August - Octombrie',
'Infuzie: 1 linguriță de fructe zdrobite la 250ml apă clocotită, se lasă 15 minute. Se beau 2 căni pe zi.',
'/images/plants/coltii-babei', '#A5D6A7', 'Coltii babei'),

(5, 'Floarea soarelui', 'Helianthus annuus', 'Sunflower', 'Asteraceae',
'Plantă anuală impunătoare, cultivată pe scară largă în județul Galați. Semințele sunt bogate în vitamina E, seleniu și acizi grași nesaturați.',
'Cultivată pe câmpuri; spontană pe terenuri ruderale',
'Septembrie - Octombrie (semințele)',
'Semințele se consumă crude sau ușor prăjite. Uleiul presat la rece se folosește în alimentație. Infuzie din petale: 2 linguri la 500ml apă.',
'/images/plants/floarea-soarelui', '#FFD54F', 'Floarea soarelui'),

(6, 'Gălbenele', 'Calendula officinalis', 'Marigold', 'Asteraceae',
'Plantă anuală cultivată frecvent în grădinile din România, atât decorativ cât și medicinal. Florile au culoare portocalie intensă.',
'Grădini, culturi; rar spontană',
'Iunie - Octombrie',
'Infuzie: 1-2 lingurite de petale uscate la 250ml apă clocotită, se lasă 10 minute. Extern: unguent din petale cu untură.',
'/images/plants/galbenele', '#FFA726', 'Galbenele'),

(7, 'Hibiscus', 'Hibiscus sabdariffa', 'Hibiscus', 'Malvaceae',
'Plantă tropicală ale cărei flori sunt folosite pentru ceaiuri aromate și medicinale. Ceaiul are gust acrișor și culoare roșu intens.',
'Cultivată în zonele tropicale; în România doar în sere sau ghivece',
'Tot anul (import uscat)',
'Infuzie: 2 lingurite de flori uscate la 250ml apă clocotită, se lasă 5-10 minute. Se poate bea cald sau rece.',
'/images/plants/hibiscus', '#EF5350', 'Hibiscus'),

(8, 'Iasomie', 'Jasminum officinale', 'Jasmine', 'Oleaceae',
'Plantă cățărătoare cu flori albe puternic parfumate, cultivată în grădinile din sudul României. Are proprietăți calmante și antidepresive.',
'Grădini, cultivată pe suporturi; prefere zone însorite și adăpostite',
'Iunie - Septembrie',
'Infuzie: 1 linguriță de flori uscate la 250ml apă clocotită, se lasă 5 minute. Se beau 2 căni pe zi, seara.',
'/images/plants/iasomie', '#F5F5F5', 'Iasomie'),

(9, 'Lavandă', 'Lavandula angustifolia', 'Lavender', 'Lamiaceae',
'Plantă aromatică perenă, cultivată în România pentru uleiul esențial. Câmpurile de lavandă din județul Galați sunt din ce în ce mai populare.',
'Cultivată pe dealuri însorite, sol calcaros',
'Iunie - August',
'Infuzie: 1-2 lingurite de flori uscate la 250ml apă clocotită, se lasă 10 minute. Ulei esențial: 2-3 picături în difuzor.',
'/images/plants/lavanda', '#CE93D8', 'Lavanda'),

(10, 'Mentă', 'Mentha piperita', 'Peppermint', 'Lamiaceae',
'Plantă perenă aromatică, extrem de răspândită în grădinile românești. Are miros puternic și gust răcoritor datorită mentolului.',
'Grădini, locuri umede, margini de pâraie',
'Iunie - August',
'Infuzie: 1-2 lingurite de frunze la 250ml apă clocotită, se lasă 5-10 minute. Se beau 3-4 căni pe zi.',
'/images/plants/menta', '#4CAF50', 'Menta'),

(11, 'Mușețel', 'Matricaria chamomilla', 'Chamomile', 'Asteraceae',
'Una dintre cele mai populare plante medicinale din România, crește spontan pe câmpuri și marginea drumurilor. Are flori mici albe cu centru galben.',
'Câmpuri, marginea drumurilor, terenuri necultivate',
'Mai - Iulie',
'Infuzie: 2-3 lingurite de flori uscate la 250ml apă clocotită, se lasă 10-15 minute acoperit. Se beau 3-4 căni pe zi.',
'/images/plants/musetel', '#FFF9C4', 'Musetel'),

(12, 'Păpădie', 'Taraxacum officinale', 'Dandelion', 'Asteraceae',
'Plantă perenă extrem de comună în România, considerată adesea buruiană, dar cu proprietăți medicinale remarcabile. Toate părțile plantei sunt utilizabile.',
'Pajiști, grădini, marginea drumurilor — peste tot',
'Aprilie - Mai (frunze), Septembrie - Octombrie (rădăcina)',
'Salată din frunze tinere. Decoct din rădăcină: 2 linguri la 500ml apă, se fierbe 10 minute. Sirop din flori.',
'/images/plants/papadie', '#FFCA28', 'Papadie'),

(13, 'Pelin', 'Artemisia absinthium', 'Wormwood', 'Asteraceae',
'Plantă perenă cu gust foarte amar, răspândită în zone uscate din România. Este una dintre cele mai vechi plante medicinale cunoscute.',
'Terenuri uscate, marginea drumurilor, coaste de deal',
'Iulie - August',
'Infuzie: 1/2 linguriță de plantă uscată la 250ml apă clocotită (ATENȚIE: doze mici!). Se bea o cană pe zi, maximum 2 săptămâni.',
'/images/plants/pelin', '#AED581', 'Pelin'),

(14, 'Rostopască', 'Chelidonium majus', 'Greater Celandine', 'Papaveraceae',
'Plantă perenă care crește pe lângă garduri, ziduri și locuri umbroase. Sucul portocaliu din tulpină este folosit tradițional pentru negi.',
'Lângă garduri, ziduri, locuri umbroase și ruderale',
'Mai - Septembrie',
'Extern: sucul proaspăt din tulpină se aplică direct pe negi/bătături, de 2-3 ori pe zi. Intern: doar sub supraveghere medicală!',
'/images/plants/rostopasca', '#FF8A65', 'Rostopasca'),

(15, 'Salvie', 'Salvia officinalis', 'Sage', 'Lamiaceae',
'Plantă perenă aromatică, cultivată frecvent în grădinile românești. Numele latin \"Salvia\" vine de la \"salvare\" - a vindeca.',
'Grădini, cultivată; spontană pe coaste uscate, însorite',
'Mai - Iulie',
'Infuzie: 1-2 lingurite de frunze uscate la 250ml apă clocotită, se lasă 10 minute. Gargarisme pentru dureri de gât.',
'/images/plants/salvie', '#81C784', 'Salvie'),

(16, 'Sunătoare', 'Hypericum perforatum', 'St. John''s Wort', 'Hypericaceae',
'Plantă perenă comună în România, crește pe dealuri, pajiști și margini de pădure. Are flori galbene și frunze cu puncte translucide.',
'Dealuri, pajiști, margini de pădure, terenuri uscate',
'Iunie - August',
'Infuzie: 2 lingurite de plantă uscată la 250ml apă clocotită, se lasă 10 minute. Ulei: flori proaspete macerate în ulei de măsline 40 zile la soare.',
'/images/plants/sunatoare', '#FDD835', 'Sunatoare'),

(17, 'Trandafir', 'Rosa damascena', 'Rose', 'Rosaceae',
'Arbust cultivat în grădinile din România, cu flori parfumate folosite în cosmetică și medicină. Petalele sunt bogate în vitamina C.',
'Grădini, cultivat; spontan pe margini de pădure (măceș)',
'Mai - Iunie (petalele), Septembrie - Octombrie (măceșele)',
'Infuzie din petale: 2 linguri la 250ml apă clocotită, se lasă 10 minute. Sirop de trandafiri. Apă de trandafiri (distilat).',
'/images/plants/trandafir', '#F48FB1', 'Trandafir'),

(18, 'Urzică', 'Urtica dioica', 'Stinging Nettle', 'Urticaceae',
'Plantă perenă foarte comună în România, crește în locuri umede și fertile. Deși arde la atingere, este extrem de nutritivă și medicinală.',
'Locuri umede, fertile, margini de pădure, grădini',
'Aprilie - Mai (frunze tinere), Septembrie (rădăcina)',
'Infuzie: 2-3 lingurite de frunze uscate la 250ml apă clocotită, se lasă 10-15 minute. Ciorbă de urzici din frunze tinere.',
'/images/plants/urzica', '#43A047', 'Urzica'),

(19, 'Valeriană', 'Valeriana officinalis', 'Valerian', 'Caprifoliaceae',
'Plantă perenă care crește în locuri umede din România. Rădăcina are miros puternic și este folosită ca sedativ natural de secole.',
'Locuri umede, pajiști de munte, margini de pârâu',
'Septembrie - Octombrie (rădăcina, anul II)',
'Infuzie din rădăcină: 1 linguriță de rădăcină mărunțită la 250ml apă clocotită, se lasă 15 minute. Se bea seara, cu 30 min înainte de culcare.',
'/images/plants/valeriana', '#B39DDB', 'Valeriana');

-- ============================================
-- PLANT_USABLE_PARTS (părți utilizabile, normalizat)
-- ============================================
INSERT INTO plant_usable_parts (plant_id, part) VALUES
-- 1. Aloe Vera
(1, 'Gelul din interiorul frunzelor'), (1, 'Sucul frunzelor'),
-- 2. Brusture
(2, 'Rădăcina'), (2, 'Frunzele tinere'), (2, 'Semințele'),
-- 3. Coada șoricelului
(3, 'Tulpini'), (3, 'Frunze'), (3, 'Flori'),
-- 4. Colții babei
(4, 'Fructele'), (4, 'Părțile aeriene'),
-- 5. Floarea soarelui
(5, 'Semințele'), (5, 'Petalele'), (5, 'Frunzele tinere'),
-- 6. Gălbenele
(6, 'Florile (petalele)'), (6, 'Frunzele tinere'),
-- 7. Hibiscus
(7, 'Florile (caliciul și petalele)'), (7, 'Frunzele tinere'),
-- 8. Iasomie
(8, 'Florile'), (8, 'Frunzele'),
-- 9. Lavandă
(9, 'Florile'), (9, 'Tulpinile tinere cu flori'),
-- 10. Mentă
(10, 'Frunzele'), (10, 'Tulpinile tinere'),
-- 11. Mușețel
(11, 'Florile (capitulele florale)'),
-- 12. Păpădie
(12, 'Frunzele'), (12, 'Rădăcina'), (12, 'Florile'), (12, 'Tulpina'),
-- 13. Pelin
(13, 'Frunzele'), (13, 'Vârfurile florale'),
-- 14. Rostopască
(14, 'Tulpina (sucul)'), (14, 'Frunzele'), (14, 'Rădăcina'),
-- 15. Salvie
(15, 'Frunzele'),
-- 16. Sunătoare
(16, 'Florile'), (16, 'Frunzele'), (16, 'Tulpinile subțiri'),
-- 17. Trandafir
(17, 'Petalele'), (17, 'Fructele (măceșele)'), (17, 'Frunzele tinere'),
-- 18. Urzică
(18, 'Frunzele tinere'), (18, 'Rădăcina'), (18, 'Semințele'),
-- 19. Valeriană
(19, 'Rădăcina'), (19, 'Rizomul');

-- ============================================
-- BENEFICII PLANTE
-- ============================================

-- 1. Aloe Vera
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(1, 'Hidratează și regenerează pielea'),
(1, 'Vindecă arsurile și rănile superficiale'),
(1, 'Calmează iritațiile pielii și eczemele'),
(1, 'Susține digestia și ameliorează constipația'),
(1, 'Are proprietăți antiinflamatorii');

-- 2. Brusture
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(2, 'Purifică sângele și elimină toxinele'),
(2, 'Tratează afecțiunile pielii (acnee, eczeme, psoriazis)'),
(2, 'Stimulează funcția ficatului'),
(2, 'Are efect diuretic natural'),
(2, 'Reglează glicemia');

-- 3. Coada șoricelului
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(3, 'Oprește hemoragiile și vindecă rănile'),
(3, 'Ameliorează durerile menstruale'),
(3, 'Îmbunătățește digestia'),
(3, 'Are proprietăți antiinflamatorii'),
(3, 'Reduce febra');

-- 4. Colții babei
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(4, 'Crește nivelul de testosteron natural'),
(4, 'Îmbunătățește libidoul și fertilitatea'),
(4, 'Susține sănătatea tractului urinar'),
(4, 'Are efect tonic și energizant'),
(4, 'Susține sănătatea cardiovasculară');

-- 5. Floarea soarelui
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(5, 'Bogată în vitamina E (antioxidant puternic)'),
(5, 'Reduce colesterolul rău (LDL)'),
(5, 'Susține sănătatea cardiovasculară'),
(5, 'Întărește sistemul imunitar'),
(5, 'Are efect antiinflamator');

-- 6. Gălbenele
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(6, 'Vindecă rănile și arsurile (extern)'),
(6, 'Are proprietăți antifungice și antibacteriene'),
(6, 'Calmează inflamațiile pielii'),
(6, 'Ameliorează ulcerul gastric'),
(6, 'Reglează ciclul menstrual');

-- 7. Hibiscus
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(7, 'Scade tensiunea arterială'),
(7, 'Bogat în vitamina C și antioxidanți'),
(7, 'Reduce colesterolul'),
(7, 'Susține sănătatea ficatului'),
(7, 'Ajută la slăbit (accelerează metabolismul)');

-- 8. Iasomie
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(8, 'Reduce stresul și anxietatea'),
(8, 'Îmbunătățește calitatea somnului'),
(8, 'Are efect antidepresiv natural'),
(8, 'Calmează durerile de cap'),
(8, 'Are proprietăți antiseptice');

-- 9. Lavandă
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(9, 'Reduce anxietatea și stresul'),
(9, 'Îmbunătățește somnul'),
(9, 'Calmează durerile de cap și migrenele'),
(9, 'Are efect antiseptic și cicatrizant'),
(9, 'Relaxează mușchii și reduce tensiunea');

-- 10. Mentă
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(10, 'Ameliorează tulburările digestive'),
(10, 'Calmează greața și vărsăturile'),
(10, 'Reduce durerile de cap'),
(10, 'Descongestionează căile respiratorii'),
(10, 'Are efect răcoritor și revigorant');

-- 11. Mușețel
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(11, 'Calmează nervii și reduce anxietatea'),
(11, 'Îmbunătățește somnul'),
(11, 'Ameliorează colicile și durerile abdominale'),
(11, 'Are efect antiinflamator (intern și extern)'),
(11, 'Tratează inflamațiile oculare (comprese)');

-- 12. Păpădie
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(12, 'Stimulează funcția ficatului și a vezicii biliare'),
(12, 'Are efect diuretic puternic'),
(12, 'Bogată în vitamine (A, C, K) și minerale'),
(12, 'Ajută la detoxifierea organismului'),
(12, 'Reglează digestia');

-- 13. Pelin
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(13, 'Stimulează apetitul și digestia'),
(13, 'Are efect antiparazitar (viermi intestinali)'),
(13, 'Ameliorează durerile de stomac'),
(13, 'Are proprietăți antiinflamatorii'),
(13, 'Tratează afecțiunile biliare');

-- 14. Rostopască
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(14, 'Tratează negii și bătăturile (extern, suc din tulpină)'),
(14, 'Susține sănătatea ficatului'),
(14, 'Are proprietăți antispastice'),
(14, 'Stimulează secreția biliară'),
(14, 'Are efect antimicrobian');

-- 15. Salvie
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(15, 'Tratează durerile de gât și inflamațiile bucale'),
(15, 'Reduce transpirația excesivă'),
(15, 'Ameliorează simptomele menopauzei'),
(15, 'Îmbunătățește memoria și concentrarea'),
(15, 'Are proprietăți antibacteriene');

-- 16. Sunătoare
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(16, 'Tratează depresia ușoară și moderată'),
(16, 'Reduce anxietatea și insomnia'),
(16, 'Vindecă rănile și arsurile (uleiul de sunătoare)'),
(16, 'Are efect antiviral'),
(16, 'Ameliorează durerile nevralgice');

-- 17. Trandafir
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(17, 'Bogat în vitamina C (mai ales măceșele)'),
(17, 'Tonifică și hidratează pielea'),
(17, 'Reduce stresul și anxietatea (aromaterapie)'),
(17, 'Are efect ușor laxativ'),
(17, 'Întărește sistemul imunitar');

-- 18. Urzică
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(18, 'Combate anemia (bogată în fier)'),
(18, 'Are efect antiinflamator puternic'),
(18, 'Tratează afecțiunile reumatice'),
(18, 'Purifică sângele și detoxifică organismul'),
(18, 'Stimulează creșterea părului');

-- 19. Valeriană
INSERT INTO plant_benefits (plant_id, benefit) VALUES
(19, 'Combate insomnia (sedativ natural)'),
(19, 'Reduce anxietatea și stresul'),
(19, 'Relaxează mușchii și reduce crampele'),
(19, 'Ameliorează durerile de cap de tensiune'),
(19, 'Calmează palpitațiile cardiace');

-- ============================================
-- CONTRAINDICAȚII PLANTE
-- ============================================

INSERT INTO plant_contraindications (plant_id, contraindication) VALUES
-- 1. Aloe Vera
(1, 'Contraindicat în sarcină (poate provoca contracții)'),
(1, 'Nu se administrează intern copiilor sub 12 ani'),
(1, 'Poate interacționa cu medicamente pentru diabet'),

-- 2. Brusture
(2, 'Evitați în sarcină și alăptare'),
(2, 'Poate interacționa cu anticoagulantele'),
(2, 'Persoanele alergice la plante din familia Asteraceae'),

-- 3. Coada șoricelului
(3, 'Contraindicată în sarcină'),
(3, 'Nu se folosește în caz de alergie la plante din familia Asteraceae'),
(3, 'Poate interacționa cu anticoagulantele'),

-- 4. Colții babei
(4, 'Nu se administrează în sarcină și alăptare'),
(4, 'Contraindicat persoanelor cu probleme hormonale'),
(4, 'Poate interacționa cu medicamente pentru diabet și tensiune'),

-- 5. Floarea soarelui
(5, 'Alergii la plante din familia Asteraceae'),
(5, 'Consumul excesiv de semințe poate crește aportul caloric'),
(5, 'Semințele sărate sunt contraindicate în hipertensiune'),

-- 6. Gălbenele
(6, 'Contraindicată în sarcină'),
(6, 'Alergie la plante din familia Asteraceae'),
(6, 'Poate interacționa cu sedativele'),

-- 7. Hibiscus
(7, 'Contraindicat persoanelor cu tensiune scăzută'),
(7, 'Nu se consumă în sarcină (poate induce contracții)'),
(7, 'Poate interacționa cu medicamentele antihipertensive'),

-- 8. Iasomie
(8, 'Evitați în sarcină (primele luni)'),
(8, 'Consumul excesiv poate provoca dureri de cap'),
(8, 'Poate provoca reacții alergice la persoanele sensibile'),

-- 9. Lavandă
(9, 'Nu se aplică ulei esențial nediluat pe piele'),
(9, 'Evitați în sarcină (primele luni)'),
(9, 'Poate provoca somnolență (nu conduceți după consum)'),

-- 10. Mentă
(10, 'Contraindicată în reflux gastroesofagian'),
(10, 'Nu se administrează copiilor sub 3 ani'),
(10, 'Poate reduce producția de lapte matern'),

-- 11. Mușețel
(11, 'Alergie la plante din familia Asteraceae'),
(11, 'Poate interacționa cu anticoagulantele'),
(11, 'Consumul excesiv poate provoca vărsături'),

-- 12. Păpădie
(12, 'Contraindicată persoanelor cu calculi biliari'),
(12, 'Poate interacționa cu diureticele și anticoagulantele'),
(12, 'Poate provoca reacții alergice'),

-- 13. Pelin
(13, 'TOXIC în doze mari! Se respectă strict dozajul'),
(13, 'Absolut contraindicat în sarcină'),
(13, 'Nu se administrează copiilor'),
(13, 'Nu se folosește mai mult de 2 săptămâni consecutiv'),

-- 14. Rostopască
(14, 'Sucul este TOXIC intern în doze mari'),
(14, 'Contraindicată în sarcină și alăptare'),
(14, 'Poate provoca iritații ale pielii la aplicare'),
(14, 'Uz intern doar sub supraveghere medicală'),

-- 15. Salvie
(15, 'Contraindicată în sarcină și alăptare'),
(15, 'Nu se administrează persoanelor cu epilepsie'),
(15, 'Consumul excesiv poate fi toxic (tujonă)'),

-- 16. Sunătoare
(16, 'Interacționează cu MULTE medicamente (antidepresive, contraceptive, anticoagulante)'),
(16, 'Provoacă fotosensibilitate (evitați expunerea la soare)'),
(16, 'Nu se asociază cu alte antidepresive'),

-- 17. Trandafir
(17, 'Persoanele alergice la trandafiri'),
(17, 'Consumul excesiv de măcese poate provoca diaree'),
(17, 'Contraindicat persoanelor cu calculi renali (vitamina C)'),

-- 18. Urzică
(18, 'Contraindicată persoanelor cu retenție de lichide cauzată de insuficiență cardiacă'),
(18, 'Poate interacționa cu anticoagulantele și antihipertensivele'),
(18, 'Se consumă doar gătită sau uscată (proaspătă arde)'),

-- 19. Valeriană
(19, 'Nu se asociază cu alcoolul sau sedativele'),
(19, 'Poate provoca somnolență (nu conduceți după consum)'),
(19, 'Nu se administrează copiilor sub 3 ani'),
(19, 'Nu se folosește mai mult de 4 săptămâni consecutiv');

-- ============================================
-- POINTS OF INTEREST (16 observații în zona Galați)
-- Status: approved pentru demo pe hartă
-- ============================================
INSERT INTO points_of_interest (id, user_id, plant_id, latitude, longitude, address, comment, ai_confidence, status) VALUES
(1,  2, 11, 45.4371500, 28.0076300, 'Parcul Mihai Eminescu, Galați',
 'Mușețel în abundență lângă aleea principală', 0.94, 'approved'),
(2,  2,  9, 45.4325100, 28.0145200, 'Grădina Publică, Galați',
 'Câteva tufișuri de lavandă pe lângă gardul grădinii', 0.87, 'approved'),
(3,  3, 18, 45.4412000, 28.0023400, 'Marginea pădurii Garboavele',
 'Urzici pe o suprafață de aprox. 20 m²', 0.96, 'approved'),
(4,  3, 12, 45.4290800, 28.0198700, 'Parc zona Mazepa, Galați',
 'Păpădii peste tot pe pajiștea din parc', 0.91, 'approved'),
(5,  4, 10, 45.4355000, 28.0105600, 'Str. Brăilei, lângă piața centrală',
 'Mentă sălbatică pe lângă un canal de irigație', 0.82, 'approved'),
(6,  4,  3, 45.4480200, 28.0210300, 'Dealul Tiglina, Galați',
 'Coada șoricelului pe marginea potecii', 0.79, 'approved'),
(7,  5,  6, 45.4265400, 28.0042100, 'Str. Tecuci, grădina unei case',
 'Gălbenele cultivate, câteva au scăpat prin gard', 0.93, 'approved'),
(8,  5, 15, 45.4338900, 28.0087600, 'Parcul CFR, Galați',
 'Salvie sălbatică pe un taluz expos la soare', 0.85, 'approved'),
(9,  2, 16, 45.4401300, 28.0156800, 'Dealul Arcașilor, Galați',
 'Sunătoare în pajiștea de pe deal, suprafață mare', 0.90, 'approved'),
(10, 3,  2, 45.4318700, 27.9965400, 'Zona industrială Șiretul, lângă calea ferată',
 'Brusture pe terenul viran de lângă gară', 0.88, 'approved'),
(11, 4, 13, 45.4445600, 28.0189200, 'Dealul Tiglina II, Galați',
 'Pelin pe un teren neîntreținut', 0.76, 'approved'),
(12, 5, 17, 45.4302100, 28.0112300, 'Str. Domnească, grădina unei biserici',
 'Trandafiri de dulceață, foarte parfumați', 0.92, 'approved'),
(13, 2, 14, 45.4389400, 28.0034500, 'Str. Traian, lângă un gard vechi',
 'Rostopască, se vede sucul portocaliu la rupere', 0.84, 'approved'),
(14, 3, 19, 45.4275600, 28.0078900, 'Lacul Brateș, zona umedă',
 'Valeriană lângă malul lacului', 0.81, 'approved'),
(15, 4,  5, 45.4460200, 28.0223400, 'Câmpul de la ieșirea din Galați spre Tecuci',
 'Floarea soarelui — câmp cultivat', 0.97, 'approved'),
(16, 5,  1, 45.4330100, 28.0060800, 'Parcul Rizer, Galați',
 'Aloe Vera într-un ghiveci lângă sera din parc', 0.86, 'approved');

-- ============================================
-- COMMENTS (comentarii pe observații)
-- ============================================
INSERT INTO comments (user_id, poi_id, content) VALUES
(3, 1,  'Confirm, am fost acolo weekendul trecut. Zona e plină de mușețel!'),
(4, 1,  'Super locație! Merită vizitată primăvara.'),
(2, 3,  'Atenție, urzicile ard rău. Luați mănuși dacă vreți să recoltați.'),
(5, 4,  'Am făcut sirop de păpădie din florile de aici. Recomand!'),
(2, 7,  'Gălbenelele astea sunt superbe, culoare intensă.'),
(3, 9,  'Am confirmat cu aplicația, scor AI de 90%. Sunătoare autentică.'),
(4, 12, 'Trandafirii aceștia au parfum incredibil, sunt de damascena.'),
(5, 15, 'E un câmp imens, se vede de la kilometri distanță.');
