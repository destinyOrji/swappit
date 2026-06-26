import hashlib
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent
BACKEND_DIR = ROOT / 'backend'
FLUTTER_DIR = ROOT / 'swappit_flutter'

load_dotenv(BACKEND_DIR / '.env')

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '3306'))
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'swappit')

DEMO_USERS = [
    {
        'name': 'Alicia Chen',
        'email': 'alicia@example.com',
        'password': 'demo1234',
        'phone': '+1-555-0101',
        'bio': 'I design user-friendly interfaces and love mentoring new developers.',
        'location': 'New York',
        'verified': True,
    },
    {
        'name': 'Mateo Rivera',
        'email': 'mateo@example.com',
        'password': 'demo1234',
        'phone': '+1-555-0102',
        'bio': 'Mobile developer sharing Flutter and React Native expertise.',
        'location': 'Chicago',
        'verified': True,
    },
    {
        'name': 'Nadia Yusuf',
        'email': 'nadia@example.com',
        'password': 'demo1234',
        'phone': '+1-555-0103',
        'bio': 'I teach Python, data analysis, and machine learning basics.',
        'location': 'Austin',
        'verified': True,
    },
    {
        'name': 'Jordan Lee',
        'email': 'jordan@example.com',
        'password': 'demo1234',
        'phone': '+1-555-0104',
        'bio': 'I help teams improve branding, motion, and social content.',
        'location': 'Seattle',
        'verified': True,
    },
    {
        'name': 'Sofia Alvarez',
        'email': 'sofia@example.com',
        'password': 'demo1234',
        'phone': '+1-555-0105',
        'bio': 'Music producer and guitarist available for collaboration.',
        'location': 'Miami',
        'verified': True,
    },
]


def ensure_mysql_connection():
    conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        autocommit=True,
    )
    conn.close()


def seed_users():
    conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        autocommit=True,
    )
    cursor = conn.cursor(dictionary=True)

    cursor.execute('CREATE TABLE IF NOT EXISTS users (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(100) UNIQUE NOT NULL, phone VARCHAR(20), password VARCHAR(255) NOT NULL, photo_url VARCHAR(500), bio TEXT, location VARCHAR(100), rating DECIMAL(3,2) DEFAULT 4.00, completed_tasks INT DEFAULT 0, pending_tasks INT DEFAULT 0, verified BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)')
    cursor.execute('CREATE TABLE IF NOT EXISTS skills (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) UNIQUE NOT NULL)')
    cursor.execute('CREATE TABLE IF NOT EXISTS user_skills (user_id BIGINT, skill_id INT, type ENUM(\'offer\', \'want\') NOT NULL, PRIMARY KEY (user_id, skill_id, type), FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE, FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE)')

    # Seed skills if table is empty
    cursor.execute('SELECT COUNT(*) AS c FROM skills')
    if cursor.fetchone()['c'] == 0:
        skills = [
            'Web Development', 'Mobile Development', 'UI/UX Design', 'Graphic Design',
            'Video Editing', 'Photography', 'Music Production', 'Guitar', 'Python',
            'JavaScript', 'Data Science', 'Machine Learning', 'English Tutoring',
            'Spanish', 'Marketing', 'SEO', 'Cooking', 'Fitness Training', 'Yoga'
        ]
        for skill in skills:
            cursor.execute('INSERT IGNORE INTO skills (name) VALUES (%s)', (skill,))

    for user in DEMO_USERS:
        password_hash = hashlib.sha256(user['password'].encode()).hexdigest()
        cursor.execute(
            'SELECT id FROM users WHERE email = %s',
            (user['email'],),
        )
        existing = cursor.fetchone()
        if existing:
            cursor.execute(
                'UPDATE users SET name=%s, phone=%s, password=%s, bio=%s, location=%s, verified=%s WHERE id=%s',
                (user['name'], user['phone'], password_hash, user['bio'], user['location'], user['verified'], existing['id']),
            )
            user_id = existing['id']
        else:
            cursor.execute(
                'INSERT INTO users (name, email, phone, password, bio, location, verified) VALUES (%s, %s, %s, %s, %s, %s, %s)',
                (user['name'], user['email'], user['phone'], password_hash, user['bio'], user['location'], user['verified']),
            )
            user_id = cursor.lastrowid

        # Assign a few skills for each demo user
        skills = cursor.execute('SELECT id FROM skills ORDER BY RAND() LIMIT 3')
        skill_rows = cursor.fetchall()
        cursor.execute('DELETE FROM user_skills WHERE user_id = %s', (user_id,))
        for skill in skill_rows:
            cursor.execute('INSERT IGNORE INTO user_skills (user_id, skill_id, type) VALUES (%s, %s, %s)', (user_id, skill['id'], 'offer'))

    conn.close()
    print('Demo users seeded successfully.')


def start_backend():
    print('Starting backend...')
    subprocess.Popen(
        [sys.executable, 'server.js'],
        cwd=str(BACKEND_DIR),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    time.sleep(5)


def start_flutter():
    print('Starting Flutter app...')
    flutter_bin = shutil.which('flutter')
    if not flutter_bin:
        raise FileNotFoundError('Flutter executable not found on PATH')

    subprocess.Popen(
        [flutter_bin, 'run', '-d', 'chrome', '--web-port=3000'],
        cwd=str(FLUTTER_DIR),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def main():
    print('Seeding demo users...')
    ensure_mysql_connection()
    seed_users()
    start_backend()
    start_flutter()
    print('\nProject is running!')
    print('Backend: http://localhost:5000/health')
    print('Frontend: http://localhost:3000')
    print('Demo login accounts:')
    for user in DEMO_USERS:
        print(f"- {user['email']} / {user['password']}")


if __name__ == '__main__':
    main()
