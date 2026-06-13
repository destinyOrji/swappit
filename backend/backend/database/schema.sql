-- ============================================
-- Swappit Database Schema
-- ============================================

CREATE DATABASE IF NOT EXISTS swappit;
USE swappit;

-- Users
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    photo_url VARCHAR(500),
    bio TEXT,
    location VARCHAR(100),
    rating DECIMAL(3,2) DEFAULT 4.00,
    completed_tasks INT DEFAULT 0,
    pending_tasks INT DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_rating (rating)
);

-- Skills master list
CREATE TABLE IF NOT EXISTS skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    INDEX idx_name (name)
);

-- User skills (offer or want)
CREATE TABLE IF NOT EXISTS user_skills (
    user_id BIGINT,
    skill_id INT,
    type ENUM('offer', 'want') NOT NULL,
    PRIMARY KEY (user_id, skill_id, type),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

-- Trade Requests
CREATE TABLE IF NOT EXISTS trade_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT,
    to_user_id BIGINT,
    offered_skill_id INT,
    requested_skill_id INT,
    status ENUM('pending', 'accepted', 'rejected', 'completed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (offered_skill_id) REFERENCES skills(id),
    FOREIGN KEY (requested_skill_id) REFERENCES skills(id),
    INDEX idx_from_user (from_user_id),
    INDEX idx_to_user (to_user_id),
    INDEX idx_status (status)
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    trade_id BIGINT NULL,
    sender_id BIGINT,
    receiver_id BIGINT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trade_id) REFERENCES trade_requests(id) ON DELETE SET NULL,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sender_receiver (sender_id, receiver_id),
    INDEX idx_trade (trade_id)
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    title VARCHAR(100),
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);

-- Ratings
CREATE TABLE IF NOT EXISTS ratings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT,
    to_user_id BIGINT,
    trade_id BIGINT,
    stars DECIMAL(3,2),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (trade_id) REFERENCES trade_requests(id) ON DELETE SET NULL,
    UNIQUE KEY unique_rating (from_user_id, trade_id)
);

-- ─── Seed: Default Skills ─────────────────────────────────
INSERT IGNORE INTO skills (name) VALUES
('Web Development'), ('Mobile Development'), ('UI/UX Design'),
('Graphic Design'), ('Video Editing'), ('Photography'),
('Music Production'), ('Guitar'), ('Piano'), ('Singing'),
('English Tutoring'), ('Math Tutoring'), ('Spanish'),
('French'), ('Arabic'), ('Python'), ('JavaScript'),
('Data Science'), ('Machine Learning'), ('3D Modeling'),
('Animation'), ('Copywriting'), ('Social Media Marketing'),
('SEO'), ('Excel'), ('Accounting'), ('Legal Advice'),
('Cooking'), ('Fitness Training'), ('Yoga'),
('Interior Design'), ('Architecture'), ('Carpentry'),
('Plumbing'), ('Electrical Work'), ('Car Repair');
