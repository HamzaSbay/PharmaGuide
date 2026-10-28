-- ==============================================================================
-- PharmaGuide TN — Production Database Seed Data (Tunisia)
-- Covers: Master Drugs, 24 Governorates Pharmacies, Initial Inventories & Garde Shifts
-- ==============================================================================

-- 1. Master Drugs Seed
INSERT INTO master_drugs (id, brand_name, dci_name, dosage, form, pct_code, category, arabic_name, aliases, requires_prescription, is_cnam_reimbursable, is_blacklisted, side_effects, contraindications, interactions)
VALUES
('drug-1', 'Doliprane 1000mg', 'Paracetamol', '1000mg', 'Comprimé / Gélule', 'PCT-10492', 'Fièvre & Douleur', 'دولبران 1000', ARRAY['dawaa el sekkri', 'wjaa al rass', 'sodaa', 'grippe', 'fevre'], false, true, false, 'Nausées légères, somnolence possible en cas de surdosage.', 'Insuffisance hépatique sévère ou hypersensibilité au paracétamol.', 'Consommation d''alcool, anticoagulants oraux.'),
('drug-2', 'Doliprane Sirop 2.4%', 'Paracetamol', '2.4%', 'Sirop Pédiatrique', 'PCT-10493', 'Fièvre & Douleur', 'دولبران سيرو', ARRAY['dawaa al atfal', 'khonjo', 'grippe'], false, true, false, 'Aucun effet notoire.', 'Allergie au paracétamol.', 'Aucune.'),
('drug-3', 'Augmentin 1g', 'Amoxicilline + Acide Clavulanique', '1g/125mg', 'Sachet Poudre', 'PCT-10022', 'Antibiotiques', 'أوقمنتين 1 غرام', ARRAY['antibiotique', 'gorge', 'infection', 'hbaab'], true, true, false, 'Troubles digestifs, diarrhée, mycose buccale.', 'Allergie aux pénicillines et céphalosporines.', 'Méthotrexate, probénécide.'),
('drug-4', 'Aspegic 500mg', 'Acide Acétylsalicylique', '500mg', 'Sachet Poudre', 'PCT-10114', 'Fièvre & Douleur', 'أسبجيك 500', ARRAY['aspegic', 'wjaa', 'ras'], false, true, false, 'Maux d''estomac, bourdonnements d''oreilles.', 'Ulcère gastrique, risque hémorragique, allergie à l''aspirine.', 'Anticoagulants (Sintrom), Ibuprofène, AINS.'),
('drug-5', 'Glucophage 1000mg', 'Metformine', '1000mg', 'Comprimé Enrobé', 'PCT-10771', 'Diabète & Métabolisme', 'غلوكوفاج 1000', ARRAY['dawaa el sekkri', 'diabete', 'sokkor'], true, true, false, 'Troubles gastro-intestinaux transitoires.', 'Acidose lactique, insuffisance rénale sévère.', 'Produits de contraste iodés, alcool.'),
('drug-6', 'Aprovel 150mg', 'Irbésartan', '150mg', 'Comprimé', 'PCT-10884', 'Cœur & Tension', 'أبروفيل 150', ARRAY['dawaa el tension', 'dham', 'coeur'], true, true, false, 'Sensations vertigineuses, fatigue.', 'Grossesse (2ème et 3ème trimestres), sténose rénale.', 'Diurétiques épargneurs de potassium, lithium.'),
('drug-7', 'Tahor 20mg', 'Atorvastatine', '20mg', 'Comprimé Pelliculé', 'PCT-11002', 'Cardiologie & Cholestérol', 'طاهور 20', ARRAY['cholesterol', 'tahor', 'chahm'], true, true, false, 'Douleurs musculaires, crampes, nausées.', 'Affections hépatiques évolutives, myopathie.', 'Fibrates, ciclosporine, clarithromycine.'),
('drug-8', 'Ventoline 100mcg', 'Salbutamol', '100mcg/dose', 'Aérosol Inhalateur', 'PCT-10991', 'Pneumologie & Asthme', 'فنتولين بخاخ', ARRAY['dawaa el diqa', 'fentoline', 'astma', 'bakhakha'], true, true, false, 'Tremblements fins des extrémités, tachycardie.', 'Allergie au salbutamol.', 'Bêtabloquants non cardiosélectifs.'),
('drug-9', 'Sintrom 4mg', 'Acénocoumarol', '4mg', 'Comprimé Sécable', 'PCT-10555', 'Anticoagulants & Sang', 'سنتروم 4', ARRAY['dawaa eddam', 'tkhathour', 'fluidifiant'], true, true, false, 'Hémorragies gingivales ou sous-cutanées.', 'Ulcère gastro-duodénal évolutif, grossesse.', 'Aspirine, AINS, antibiotiques, millepertuis.')
ON CONFLICT (id) DO UPDATE SET
  brand_name = EXCLUDED.brand_name,
  dci_name = EXCLUDED.dci_name,
  category = EXCLUDED.category;

-- 2. Tunisian Pharmacies Seed (24 Governorates)
INSERT INTO pharmacies (id, cnop_id, name, address, governorate, phone, location, accepts_cnam, is_garde, is_open)
VALUES
('ph-1', 'CNOP-1042', 'Pharmacie Centrale de Nuit', 'Avenue Habib Bourguiba, Tunis', 'Tunis', '+216 71 245 678', ST_SetSRID(ST_MakePoint(10.1815, 36.8008), 4326)::geography, true, true, true),
('ph-2', 'CNOP-1088', 'Pharmacie Central Habib Bourguiba', 'Rue de Rome, Tunis Centre', 'Tunis', '+216 71 334 556', ST_SetSRID(ST_MakePoint(10.1795, 36.7995), 4326)::geography, true, false, true),
('ph-3', 'CNOP-2015', 'Pharmacie du Lac', 'Les Berges du Lac 1, Tunis', 'Tunis', '+216 71 960 123', ST_SetSRID(ST_MakePoint(10.2355, 36.8335), 4326)::geography, true, false, true),
('ph-4', 'CNOP-2240', 'Pharmacie Ennasr', 'Avenue Hédi Nouira, Ennasr 2', 'Ariana', '+216 71 828 900', ST_SetSRID(ST_MakePoint(10.1580, 36.8620), 4326)::geography, true, true, true),
('ph-5', 'CNOP-3105', 'Pharmacie Médina Mégrine', 'Avenue Habib Bourguiba, Mégrine', 'Ben Arous', '+216 71 295 440', ST_SetSRID(ST_MakePoint(10.2380, 36.7680), 4326)::geography, true, false, true),
('ph-6', 'CNOP-3490', 'Pharmacie de Nuit Manouba', 'Boulevard de l''Environnement, Denden', 'Manouba', '+216 71 602 110', ST_SetSRID(ST_MakePoint(10.1120, 36.8080), 4326)::geography, true, true, true),
('ph-7', 'CNOP-4012', 'Pharmacie du Port Nabeul', 'Avenue Habib Thameur, Nabeul', 'Nabeul', '+216 72 285 300', ST_SetSRID(ST_MakePoint(10.7350, 36.4550), 4326)::geography, true, true, true),
('ph-8', 'CNOP-4550', 'Pharmacie Yasmine Hammamet', 'Boulevard de la Marina, Hammamet Sud', 'Nabeul', '+216 72 240 100', ST_SetSRID(ST_MakePoint(10.5500, 36.3750), 4326)::geography, false, false, true),
('ph-9', 'CNOP-5001', 'Pharmacie du Vieux Port', 'Quai Tarak Ibn Ziad, Bizerte', 'Bizerte', '+216 72 431 220', ST_SetSRID(ST_MakePoint(9.8730, 37.2740), 4326)::geography, true, true, true),
('ph-10', 'CNOP-6010', 'Pharmacie Ribat Sousse', 'Avenue Habib Bourguiba, Sousse Centre', 'Sousse', '+216 73 225 600', ST_SetSRID(ST_MakePoint(10.6380, 35.8280), 4326)::geography, true, true, true),
('ph-11', 'CNOP-6520', 'Pharmacie du Port de Sfax', 'Avenue Hédi Chaker, Sfax', 'Sfax', '+216 74 220 880', ST_SetSRID(ST_MakePoint(10.7640, 34.7390), 4326)::geography, true, true, true),
('ph-12', 'CNOP-7015', 'Pharmacie de Nuit Monastir', 'Boulevard du 7 Novembre, Monastir', 'Monastir', '+216 73 461 300', ST_SetSRID(ST_MakePoint(10.8280, 35.7720), 4326)::geography, true, true, true),
('ph-13', 'CNOP-8020', 'Pharmacie Djerba Houmt Souk', 'Rue Taieb Mhiri, Houmt Souk, Djerba', 'Medenine', '+216 75 650 400', ST_SetSRID(ST_MakePoint(10.8570, 33.8760), 4326)::geography, true, true, true),
('ph-14', 'CNOP-9011', 'Pharmacie Oasis Tozeur', 'Avenue Farhat Hached, Tozeur', 'Tozeur', '+216 76 452 100', ST_SetSRID(ST_MakePoint(8.1330, 33.9190), 4326)::geography, true, false, true),
('ph-15', 'CNOP-9502', 'Pharmacie du Sud Gabès', 'Boulevard Mohamed Ali, Gabès', 'Gabès', '+216 75 271 500', ST_SetSRID(ST_MakePoint(10.1000, 33.8830), 4326)::geography, true, true, true),
('ph-16', 'CNOP-ZG-1040', 'Pharmacie Temple des Eaux', 'Avenue de l''Indépendance, Zaghouan', 'Zaghouan', '+216 72 675 300', ST_SetSRID(ST_MakePoint(10.1429, 36.4029), 4326)::geography, true, true, true),
('ph-17', 'CNOP-BJ-1050', 'Pharmacie Béja Médina', 'Avenue Habib Bourguiba, Béja', 'Béja', '+216 78 450 120', ST_SetSRID(ST_MakePoint(9.1817, 36.7256), 4326)::geography, true, true, true),
('ph-18', 'CNOP-JN-1060', 'Pharmacie Tabarka Corniche', 'Avenue Habib Bourguiba, Tabarka', 'Jendouba', '+216 78 670 400', ST_SetSRID(ST_MakePoint(8.7580, 36.9540), 4326)::geography, true, true, true),
('ph-19', 'CNOP-KF-1070', 'Pharmacie Le Kef Kasbah', 'Rue Ali Belhouane, Le Kef', 'Le Kef', '+216 78 200 110', ST_SetSRID(ST_MakePoint(8.7048, 36.1742), 4326)::geography, true, false, true),
('ph-20', 'CNOP-SL-1080', 'Pharmacie Siliana Center', 'Avenue de l''Environnement, Siliana', 'Siliana', '+216 78 870 200', ST_SetSRID(ST_MakePoint(9.3708, 36.0849), 4326)::geography, true, true, true),
('ph-21', 'CNOP-MH-1090', 'Pharmacie Cap Zouila Mahdia', 'Avenue Taïeb Hachicha, Mahdia', 'Mahdia', '+216 73 680 150', ST_SetSRID(ST_MakePoint(11.0622, 35.5047), 4326)::geography, true, true, true),
('ph-22', 'CNOP-KR-1100', 'Pharmacie Okba Kairouan', 'Avenue Beit El Hikma, Kairouan', 'Kairouan', '+216 77 230 400', ST_SetSRID(ST_MakePoint(10.0963, 35.6781), 4326)::geography, true, true, true),
('ph-23', 'CNOP-KS-1110', 'Pharmacie Kasserine Center', 'Avenue Habib Bourguiba, Kasserine', 'Kasserine', '+216 77 470 300', ST_SetSRID(ST_MakePoint(8.8365, 35.1676), 4326)::geography, true, false, true),
('ph-24', 'CNOP-SB-1120', 'Pharmacie Sidi Bouzid Center', 'Avenue de la République, Sidi Bouzid', 'Sidi Bouzid', '+216 76 630 200', ST_SetSRID(ST_MakePoint(9.4858, 35.0382), 4326)::geography, true, true, true),
('ph-25', 'CNOP-TT-1130', 'Pharmacie Tataouine Ksour', 'Avenue Farhat Hached, Tataouine', 'Tataouine', '+216 75 860 100', ST_SetSRID(ST_MakePoint(10.4518, 32.9297), 4326)::geography, true, false, true),
('ph-26', 'CNOP-GF-1140', 'Pharmacie Gafsa Oasis', 'Avenue Palestine, Gafsa', 'Gafsa', '+216 76 220 500', ST_SetSRID(ST_MakePoint(8.7842, 34.4250), 4326)::geography, true, true, true),
('ph-27', 'CNOP-KB-1160', 'Pharmacie Kebili Oasis', 'Avenue de la Liberté, Kebili', 'Kebili', '+216 75 490 200', ST_SetSRID(ST_MakePoint(8.9690, 33.7044), 4326)::geography, true, true, true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  phone = EXCLUDED.phone,
  is_garde = EXCLUDED.is_garde,
  location = EXCLUDED.location;

-- 3. Inventories Seed (Linking Pharmacies to Drugs)
INSERT INTO inventories (pharmacy_id, drug_id, quantity, in_stock, last_updated)
VALUES
('ph-1', 'drug-1', 45, true, now()),
('ph-1', 'drug-3', 18, true, now()),
('ph-1', 'drug-5', 22, true, now()),
('ph-1', 'drug-8', 12, true, now()),
('ph-2', 'drug-1', 15, true, now()),
('ph-2', 'drug-4', 30, true, now()),
('ph-2', 'drug-6', 10, true, now()),
('ph-3', 'drug-1', 80, true, now()),
('ph-3', 'drug-3', 25, true, now()),
('ph-3', 'drug-7', 35, true, now()),
('ph-4', 'drug-1', 60, true, now()),
('ph-4', 'drug-2', 40, true, now()),
('ph-4', 'drug-3', 15, true, now()),
('ph-4', 'drug-5', 50, true, now()),
('ph-5', 'drug-1', 20, true, now()),
('ph-5', 'drug-4', 15, true, now()),
('ph-6', 'drug-1', 35, true, now()),
('ph-6', 'drug-8', 8, true, now()),
('ph-7', 'drug-1', 40, true, now()),
('ph-7', 'drug-3', 12, true, now()),
('ph-10', 'drug-1', 75, true, now()),
('ph-10', 'drug-3', 30, true, now()),
('ph-11', 'drug-1', 90, true, now()),
('ph-11', 'drug-5', 40, true, now()),
('ph-12', 'drug-1', 30, true, now()),
('ph-13', 'drug-1', 50, true, now()),
('ph-15', 'drug-1', 35, true, now())
ON CONFLICT (pharmacy_id, drug_id) DO UPDATE SET
  quantity = EXCLUDED.quantity,
  in_stock = EXCLUDED.in_stock,
  last_updated = now();

-- 4. Garde Shifts Seed
INSERT INTO garde_shifts (id, pharmacy_id, pharmacy_name, shift_type, start_date, end_date, governorate)
VALUES
('shift-1', 'ph-1', 'Pharmacie Centrale de Nuit', 'NUIT', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Tunis'),
('shift-2', 'ph-4', 'Pharmacie Ennasr', 'NUIT', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Ariana'),
('shift-3', 'ph-6', 'Pharmacie de Nuit Manouba', 'NUIT', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Manouba'),
('shift-4', 'ph-7', 'Pharmacie du Port Nabeul', 'DIMANCHE_FERIE', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 'Nabeul'),
('shift-5', 'ph-10', 'Pharmacie Ribat Sousse', 'NUIT', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Sousse'),
('shift-6', 'ph-11', 'Pharmacie du Port de Sfax', 'NUIT', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Sfax')
ON CONFLICT (id) DO UPDATE SET
  shift_type = EXCLUDED.shift_type,
  start_date = EXCLUDED.start_date,
  end_date = EXCLUDED.end_date;
