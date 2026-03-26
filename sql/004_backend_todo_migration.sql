-- ============================================
-- EcoLocatie - Migrare 004: BACKEND_TODO features
-- Notificari, Favorite, parent_id comentarii,
-- campuri noi POI, etc.
-- ============================================

USE ecolocatie;

-- ============================================
-- 1. Tabel: notifications
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  type       ENUM('poi_created', 'poi_approved', 'poi_rejected', 'poi_pending', 'poi_edited', 'poi_commented') NOT NULL,
  title      VARCHAR(255) NOT NULL,
  message    TEXT NOT NULL,
  is_read    BOOLEAN DEFAULT FALSE,
  poi_id     INT NULL,
  plant_name VARCHAR(255) NULL,
  reason     VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (poi_id)  REFERENCES points_of_interest(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_notif_user    ON notifications(user_id);
CREATE INDEX idx_notif_read    ON notifications(user_id, is_read);
CREATE INDEX idx_notif_created ON notifications(created_at);

-- ============================================
-- 2. Tabel: favorites (pe plante, nu pe POI-uri)
-- ============================================
CREATE TABLE IF NOT EXISTS favorites (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  plant_id   INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_fav (user_id, plant_id),
  FOREIGN KEY (user_id)  REFERENCES users(id)   ON DELETE CASCADE,
  FOREIGN KEY (plant_id) REFERENCES plants(id)   ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- 3. comments: adauga parent_id pentru reply-uri
-- ============================================
-- Verificam daca coloana exista deja
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'comments' AND COLUMN_NAME = 'parent_id');

SET @sql = IF(@col_exists = 0,
  'ALTER TABLE comments ADD COLUMN parent_id INT NULL, ADD FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 4. points_of_interest: campuri noi (descriere, habitat, etc.)
-- ============================================

-- description
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'description');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN description TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- habitat
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'habitat');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN habitat TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- harvest_period
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'harvest_period');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN harvest_period VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- benefits
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'benefits');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN benefits TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- contraindications
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'contraindications');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN contraindications TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- description_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'description_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN description_en TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- habitat_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'habitat_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN habitat_en TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- harvest_period_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'harvest_period_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN harvest_period_en VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- benefits_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'benefits_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN benefits_en TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- contraindications_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'contraindications_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN contraindications_en TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- comment_en
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecolocatie' AND TABLE_NAME = 'points_of_interest' AND COLUMN_NAME = 'comment_en');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE points_of_interest ADD COLUMN comment_en TEXT NULL', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
