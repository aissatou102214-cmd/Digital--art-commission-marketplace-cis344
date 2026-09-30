-- =====================================================================
-- Digital Art Commission Marketplace  |  CIS 344 Individual Project
-- Target: MySQL 8.0.16+ (InnoDB)
-- Run in MySQL Workbench: File > Open SQL Script, then click the lightning bolt.
-- Sections: 1) Database  2) Tables  3) Indexes  4) Trigger  5) View
--           6) Sample data  7) Sample queries / data manipulation
-- =====================================================================

-- 1) DATABASE -----------------------------------------------------------
DROP DATABASE IF EXISTS digital_art_commission_marketplace;
CREATE DATABASE digital_art_commission_marketplace
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE digital_art_commission_marketplace;

-- 2) TABLES (11) --------------------------------------------------------

-- Every account (client, artist, or admin) lives here.
CREATE TABLE Users (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,          -- store a hash, never the plain password
  display_name  VARCHAR(100) NOT NULL,
  bio           TEXT,
  role          ENUM('client','artist','admin') NOT NULL DEFAULT 'client',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 1 User : 0..1 ArtistProfile  (UNIQUE on user_id enforces the "0..1")
CREATE TABLE ArtistProfiles (
  artist_id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT NOT NULL UNIQUE,
  portfolio_url     VARCHAR(255),
  commission_status ENUM('open','closed','waitlist') NOT NULL DEFAULT 'open',
  starting_price    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  turnaround_days   INT NOT NULL DEFAULT 7,
  rating_avg        DECIMAL(3,2) NOT NULL DEFAULT 0.00,   -- kept up to date by trigger below
  CONSTRAINT chk_artist_price CHECK (starting_price >= 0),
  CONSTRAINT chk_artist_days  CHECK (turnaround_days > 0),
  CONSTRAINT fk_artist_user FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 1 User : 0..1 ClientProfile
CREATE TABLE ClientProfiles (
  client_id                INT AUTO_INCREMENT PRIMARY KEY,
  user_id                  INT NOT NULL UNIQUE,
  preferred_payment_method VARCHAR(50),
  shipping_address         VARCHAR(255),
  CONSTRAINT fk_client_user FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Central entity: links one client and one artist.
CREATE TABLE Commissions (
  commission_id INT AUTO_INCREMENT PRIMARY KEY,
  client_id     INT NOT NULL,
  artist_id     INT NOT NULL,
  title         VARCHAR(150) NOT NULL,
  brief         TEXT NOT NULL,
  budget        DECIMAL(10,2) NOT NULL,
  deadline      DATE,
  status        ENUM('pending','accepted','in_progress','delivered','completed','cancelled')
                NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at  DATETIME NULL,
  CONSTRAINT chk_commission_budget CHECK (budget > 0),
  CONSTRAINT fk_commission_client FOREIGN KEY (client_id) REFERENCES ClientProfiles(client_id) ON DELETE CASCADE,
  CONSTRAINT fk_commission_artist FOREIGN KEY (artist_id) REFERENCES ArtistProfiles(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Bridge table: resolves Commission M:N Category.
CREATE TABLE CommissionCategories (
  commission_id INT NOT NULL,
  category_id   INT NOT NULL,
  PRIMARY KEY (commission_id, category_id),
  CONSTRAINT fk_cc_commission FOREIGN KEY (commission_id) REFERENCES Commissions(commission_id) ON DELETE CASCADE,
  CONSTRAINT fk_cc_category   FOREIGN KEY (category_id)   REFERENCES Categories(category_id)   ON DELETE CASCADE
) ENGINE=InnoDB;

-- Versioned deliverables: 1 Commission : N Artworks
CREATE TABLE Artworks (
  artwork_id    INT AUTO_INCREMENT PRIMARY KEY,
  commission_id INT NOT NULL,
  title         VARCHAR(150) NOT NULL,
  file_url      VARCHAR(255) NOT NULL,
  preview_url   VARCHAR(255),
  version       INT NOT NULL DEFAULT 1,
  uploaded_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_artwork_version CHECK (version >= 1),
  CONSTRAINT uq_artwork_version UNIQUE (commission_id, version),
  CONSTRAINT fk_artwork_commission FOREIGN KEY (commission_id) REFERENCES Commissions(commission_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Deposit + final payment etc.: 1 Commission : N Payments
CREATE TABLE Payments (
  payment_id      INT AUTO_INCREMENT PRIMARY KEY,
  commission_id   INT NOT NULL,
  amount          DECIMAL(10,2) NOT NULL,
  payment_method  VARCHAR(50),
  payment_status  ENUM('pending','paid','refunded','failed') NOT NULL DEFAULT 'pending',
  paid_at         DATETIME NULL,
  transaction_ref VARCHAR(100) UNIQUE,
  CONSTRAINT chk_payment_amount CHECK (amount > 0),
  CONSTRAINT fk_payment_commission FOREIGN KEY (commission_id) REFERENCES Commissions(commission_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 1 Commission : 0..1 Review (UNIQUE on commission_id)
CREATE TABLE Reviews (
  review_id     INT AUTO_INCREMENT PRIMARY KEY,
  commission_id INT NOT NULL UNIQUE,
  reviewer_id   INT NOT NULL,
  rating        TINYINT NOT NULL,
  comment       TEXT,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT fk_review_commission FOREIGN KEY (commission_id) REFERENCES Commissions(commission_id) ON DELETE CASCADE,
  CONSTRAINT fk_review_reviewer   FOREIGN KEY (reviewer_id)   REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Messages (
  message_id    INT AUTO_INCREMENT PRIMARY KEY,
  commission_id INT NOT NULL,
  sender_id     INT NOT NULL,
  body          TEXT NOT NULL,
  sent_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_message_commission FOREIGN KEY (commission_id) REFERENCES Commissions(commission_id) ON DELETE CASCADE,
  CONSTRAINT fk_message_sender     FOREIGN KEY (sender_id)     REFERENCES Users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PortfolioItems (
  item_id     INT AUTO_INCREMENT PRIMARY KEY,
  artist_id   INT NOT NULL,
  title       VARCHAR(150) NOT NULL,
  image_url   VARCHAR(255) NOT NULL,
  description TEXT,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_portfolio_artist FOREIGN KEY (artist_id) REFERENCES ArtistProfiles(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE CommissionTypes (
  type_id        INT AUTO_INCREMENT PRIMARY KEY,
  artist_id      INT NOT NULL,
  name           VARCHAR(100) NOT NULL,
  description    TEXT,
  base_price     DECIMAL(10,2) NOT NULL,
  estimated_days INT NOT NULL,
  CONSTRAINT chk_type_price CHECK (base_price >= 0),
  CONSTRAINT chk_type_days  CHECK (estimated_days > 0),
  CONSTRAINT fk_type_artist FOREIGN KEY (artist_id) REFERENCES ArtistProfiles(artist_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 3) INDEXES (speed up common lookups) ---------------------------------
CREATE INDEX idx_commissions_status ON Commissions(status);
CREATE INDEX idx_messages_commission ON Messages(commission_id, sent_at);
CREATE INDEX idx_payments_commission ON Payments(commission_id);

-- 4) TRIGGER: keep ArtistProfiles.rating_avg current when a review is added
DELIMITER $$
CREATE TRIGGER trg_reviews_after_insert
AFTER INSERT ON Reviews
FOR EACH ROW
BEGIN
  UPDATE ArtistProfiles
  SET rating_avg = (
        SELECT ROUND(AVG(r.rating), 2)
        FROM Reviews r
        JOIN Commissions c ON c.commission_id = r.commission_id
        WHERE c.artist_id = (SELECT artist_id FROM Commissions WHERE commission_id = NEW.commission_id)
      )
  WHERE artist_id = (SELECT artist_id FROM Commissions WHERE commission_id = NEW.commission_id);
END$$
DELIMITER ;

-- 5) VIEW: one readable row per commission
CREATE VIEW vw_commission_overview AS
SELECT c.commission_id,
       c.title,
       c.status,
       c.budget,
       c.deadline,
       cu.display_name AS client_name,
       au.display_name AS artist_name,
       COALESCE(SUM(CASE WHEN p.payment_status = 'paid' THEN p.amount END), 0) AS total_paid
FROM Commissions c
JOIN ClientProfiles cp ON cp.client_id = c.client_id
JOIN Users cu          ON cu.user_id   = cp.user_id
JOIN ArtistProfiles ap ON ap.artist_id = c.artist_id
JOIN Users au          ON au.user_id   = ap.user_id
LEFT JOIN Payments p   ON p.commission_id = c.commission_id
GROUP BY c.commission_id, c.title, c.status, c.budget, c.deadline, cu.display_name, au.display_name;

-- 6) SAMPLE DATA (fictional; password hashes are dummy placeholders) ------
INSERT INTO Users (username, email, password_hash, display_name, bio, role) VALUES
('alice_client', 'alice@example.com', 'DEMO_HASH_1', 'Alice Client', 'Loves fantasy art', 'client'),
('dan_client',   'dan@example.com',   'DEMO_HASH_2', 'Dan Client',   'Indie game developer', 'client'),
('bob_artist',   'bob@example.com',   'DEMO_HASH_3', 'Bob Artist',   'Digital illustrator', 'artist'),
('carol_artist', 'carol@example.com', 'DEMO_HASH_4', 'Carol Artist', 'Character designer', 'artist'),
('admin_user',   'admin@example.com', 'DEMO_HASH_5', 'Site Admin',   'Marketplace administrator', 'admin');

INSERT INTO ClientProfiles (user_id, preferred_payment_method, shipping_address) VALUES
(1, 'PayPal', NULL),
(2, 'Credit Card', NULL);

INSERT INTO ArtistProfiles (user_id, portfolio_url, commission_status, starting_price, turnaround_days) VALUES
(3, 'https://example.com/bob',   'open',     50.00,  7),
(4, 'https://example.com/carol', 'waitlist', 80.00, 10);

INSERT INTO Categories (name) VALUES
('Character Art'), ('Landscape'), ('Portrait'), ('Concept Art');

INSERT INTO Commissions (client_id, artist_id, title, brief, budget, deadline, status, completed_at) VALUES
(1, 1, 'Fantasy Character',  'Full-body fantasy character with armor.',        150.00, '2026-10-15', 'completed',   '2026-10-10 14:30:00'),
(2, 2, 'Game Hero Concept',  'Concept sheet for a platformer hero, 3 poses.',  200.00, '2026-11-01', 'in_progress', NULL),
(1, 2, 'Pet Portrait',       'Head-and-shoulders portrait of my cat.',          60.00, '2026-11-20', 'pending',     NULL);

INSERT INTO CommissionCategories (commission_id, category_id) VALUES
(1, 1), (1, 4), (2, 4), (3, 3);

INSERT INTO Artworks (commission_id, title, file_url, preview_url, version) VALUES
(1, 'Initial Sketch',       'https://example.com/files/sketch_v1.png', 'https://example.com/previews/sketch_v1.png', 1),
(1, 'Silver Armor Update',  'https://example.com/files/sketch_v2.png', 'https://example.com/previews/sketch_v2.png', 2),
(1, 'Final Render',         'https://example.com/files/final.png',     'https://example.com/previews/final.png',    3),
(2, 'Pose Sketches',        'https://example.com/files/hero_v1.png',   'https://example.com/previews/hero_v1.png',  1);

INSERT INTO Payments (commission_id, amount, payment_method, payment_status, paid_at, transaction_ref) VALUES
(1,  75.00, 'PayPal',      'paid',    '2026-09-20 10:00:00', 'TXN-1001'),
(1,  75.00, 'PayPal',      'paid',    '2026-10-10 15:00:00', 'TXN-1002'),
(2, 100.00, 'Credit Card', 'paid',    '2026-10-05 09:15:00', 'TXN-1003'),
(2, 100.00, 'Credit Card', 'pending', NULL,                  NULL);

INSERT INTO Messages (commission_id, sender_id, body) VALUES
(1, 1, 'Hi, can you make the armor silver?'),
(1, 3, 'Yes, I will update the sketch.'),
(2, 2, 'Could the third pose be a jumping pose?'),
(2, 4, 'Sure, I will send a revised sketch this week.');

INSERT INTO PortfolioItems (artist_id, title, image_url, description) VALUES
(1, 'Knight', 'https://example.com/portfolio/knight.png', 'Armored knight illustration.'),
(2, 'Rogue',  'https://example.com/portfolio/rogue.png',  'Character design of a hooded rogue.');

INSERT INTO CommissionTypes (artist_id, name, description, base_price, estimated_days) VALUES
(1, 'Full Body',      'Full body character illustration',     100.00, 7),
(1, 'Portrait',       'Head and shoulders portrait',           50.00, 5),
(2, 'Concept Sheet',  'Multi-pose character concept sheet',   150.00, 10);

-- Review inserted last so the trigger recalculates the artist's rating_avg
INSERT INTO Reviews (commission_id, reviewer_id, rating, comment) VALUES
(1, 1, 5, 'Great communication and quality.');

-- 7) SAMPLE QUERIES / DATA MANIPULATION ---------------------------------

-- Q1: Commission overview (uses the view)
SELECT * FROM vw_commission_overview;

-- Q2: Active commissions with their categories
SELECT c.commission_id, c.title,
       GROUP_CONCAT(cat.name ORDER BY cat.name SEPARATOR ', ') AS categories
FROM Commissions c
JOIN CommissionCategories cc ON cc.commission_id = c.commission_id
JOIN Categories cat          ON cat.category_id  = cc.category_id
WHERE c.status IN ('pending','accepted','in_progress')
GROUP BY c.commission_id, c.title;

-- Q3: Latest artwork version for each commission
SELECT a.commission_id, a.title, a.version
FROM Artworks a
WHERE a.version = (SELECT MAX(version) FROM Artworks WHERE commission_id = a.commission_id);

-- Q4: Artist ratings and number of commissions
SELECT u.display_name, ap.rating_avg, COUNT(c.commission_id) AS total_commissions
FROM ArtistProfiles ap
JOIN Users u ON u.user_id = ap.user_id
LEFT JOIN Commissions c ON c.artist_id = ap.artist_id
GROUP BY ap.artist_id, u.display_name, ap.rating_avg;

-- UPDATE example: artist accepts the pending commission
UPDATE Commissions SET status = 'accepted' WHERE commission_id = 3;

-- UPDATE example: mark the pending payment as paid
UPDATE Payments
SET payment_status = 'paid', paid_at = NOW(), transaction_ref = 'TXN-1004'
WHERE payment_id = 4;

-- DELETE example: remove a portfolio item (does not affect commissions)
DELETE FROM PortfolioItems WHERE item_id = 2;
