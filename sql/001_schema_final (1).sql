-- ============================================
-- EcoLocație - Schema finală bază de date MySQL
-- Concurs Severin Bumbaru 2026
-- Versiunea: 2.1 (aliniată cu frontend mockup)
-- ============================================

CREATE DATABASE IF NOT EXISTS ecolocatie
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_romanian_ci;

USE ecolocatie;

-- Dezactivare FK checks temporar pentru DROP sigur
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS chat_history;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS points_of_interest;
DROP TABLE IF EXISTS plant_contraindications;
DROP TABLE IF EXISTS plant_benefits;
DROP TABLE IF EXISTS plant_usable_parts;
DROP TABLE IF EXISTS plants;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS config;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- TABELA: users
-- Utilizatori ai aplicației (admin + user)
-- ============================================
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  first_name    VARCHAR(50),
  last_name     VARCHAR(50),
  email         VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL       COMMENT 'Hash bcrypt/argon2 — NICIODATĂ plain text',
  phone         VARCHAR(20),
  birth_date    DATE,
  role          ENUM('user', 'admin') DEFAULT 'user',
  is_active     BOOLEAN      DEFAULT TRUE   COMMENT 'Admin poate dezactiva conturi',
  profile_image VARCHAR(255)                COMMENT 'URL avatar upload',
  created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- TABELA: plants
-- Plante medicinale — catalogul principal
-- ============================================
CREATE TABLE plants (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  name_ro        VARCHAR(100) NOT NULL      COMMENT 'Numele în română',
  name_latin     VARCHAR(100)               COMMENT 'Numele științific',
  name_en        VARCHAR(100)               COMMENT 'Numele în engleză',
  family         VARCHAR(100)               COMMENT 'Familia botanică (ex: Asteraceae, Lamiaceae)',
  description    TEXT,
  habitat        TEXT                        COMMENT 'Unde crește planta în natură',
  harvest_period VARCHAR(150)               COMMENT 'Perioada de recoltare (ex: Iunie - August)',
  preparation    TEXT                        COMMENT 'Mod de preparare / utilizare',
  image_url      VARCHAR(255)               COMMENT 'URL imagine principală plantă',
  icon_color     VARCHAR(7)   DEFAULT '#4CAF50' COMMENT 'Cod hex culoare marker pe hartă',
  folder_name    VARCHAR(100) NOT NULL      COMMENT 'Numele folderului din datasetul AI',
  created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- TABELA: plant_usable_parts
-- Părțile utilizabile ale plantei (normalizat)
-- ============================================
CREATE TABLE plant_usable_parts (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  plant_id INT          NOT NULL,
  part     VARCHAR(100) NOT NULL  COMMENT 'Ex: frunze, flori, rădăcină',
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELA: plant_benefits
-- Beneficii medicinale (4-5 per plantă)
-- ============================================
CREATE TABLE plant_benefits (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  plant_id INT          NOT NULL,
  benefit  VARCHAR(255) NOT NULL,
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELA: plant_contraindications
-- Contraindicații (2-4 per plantă)
-- ============================================
CREATE TABLE plant_contraindications (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  plant_id         INT          NOT NULL,
  contraindication VARCHAR(255) NOT NULL,
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELA: points_of_interest (POI / Observații)
-- Sighting-uri de plante pe hartă
-- ============================================
CREATE TABLE points_of_interest (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT            NOT NULL     COMMENT 'Cine a creat observația',
  plant_id      INT            NOT NULL     COMMENT 'Planta identificată',
  latitude      DECIMAL(10, 7) NOT NULL,
  longitude     DECIMAL(10, 7) NOT NULL,
  address       VARCHAR(255),
  comment       TEXT                        COMMENT 'Comentariu utilizator la observație',
  ai_confidence DECIMAL(4, 3)               COMMENT 'Scorul AI 0.000–1.000',
  status        ENUM('pending', 'approved', 'rejected') DEFAULT 'pending'
                                            COMMENT 'Flow moderare: pending → approved/rejected',
  created_at    DATETIME       DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELA: comments
-- Comentarii pe observații
-- ============================================
CREATE TABLE comments (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT  NOT NULL,
  poi_id     INT  NOT NULL,
  content    TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (poi_id)  REFERENCES points_of_interest(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- TABELA: chat_history (pentru RAG chatbot)
-- ============================================
CREATE TABLE chat_history (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT,
  question   TEXT NOT NULL,
  answer     TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- TABELA: config (configurare hartă — singleton)
-- ============================================
CREATE TABLE config (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  map_center_lat    DECIMAL(10, 7) NOT NULL DEFAULT 45.4353000,
  map_center_lng    DECIMAL(10, 7) NOT NULL DEFAULT 28.0080000,
  map_default_zoom  INT            NOT NULL DEFAULT 13,
  map_max_zoom      INT            NOT NULL DEFAULT 18,
  map_min_zoom      INT            NOT NULL DEFAULT 10,
  tile_url          VARCHAR(500)   DEFAULT 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  tile_attribution  VARCHAR(500)   DEFAULT '&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a> contributors',
  bounds_north      DECIMAL(10, 7) COMMENT 'Bounding box Galați - nord',
  bounds_south      DECIMAL(10, 7) COMMENT 'Bounding box Galați - sud',
  bounds_east       DECIMAL(10, 7) COMMENT 'Bounding box Galați - est',
  bounds_west       DECIMAL(10, 7) COMMENT 'Bounding box Galați - vest',
  active_model      VARCHAR(100)   DEFAULT 'model_densenet121.h5' COMMENT 'Modelul AI activ pentru clasificare'
) ENGINE=InnoDB;

-- ============================================
-- INDEXURI pentru performanță
-- ============================================
CREATE INDEX idx_poi_plant      ON points_of_interest(plant_id);
CREATE INDEX idx_poi_user       ON points_of_interest(user_id);
CREATE INDEX idx_poi_status     ON points_of_interest(status);
CREATE INDEX idx_poi_coords     ON points_of_interest(latitude, longitude);
CREATE INDEX idx_comments_poi   ON comments(poi_id);
CREATE INDEX idx_benefits_plant ON plant_benefits(plant_id);
CREATE INDEX idx_contra_plant   ON plant_contraindications(plant_id);
CREATE INDEX idx_parts_plant    ON plant_usable_parts(plant_id);
CREATE INDEX idx_chat_user      ON chat_history(user_id);
