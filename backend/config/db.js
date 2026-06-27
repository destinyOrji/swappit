const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'swappit',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: 'Z',
});

const ensureSchema = async () => {
  try {
    const conn = await pool.getConnection();
    const schemaPath = path.join(__dirname, '..', 'database', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await conn.query(schema);
    conn.release();
    console.log('✅ Database schema initialized');
  } catch (err) {
    console.warn(`⚠️ MySQL connection failed: ${err.message}`);
    console.warn('Continuing without a database connection so the backend can still start. Configure backend/.env or start MySQL to enable DB-backed features.');
  }
};

(async () => {
  try {
    const conn = await pool.getConnection();
    console.log('✅ MySQL connected successfully');
    conn.release();
    await ensureSchema();
  } catch (err) {
    console.warn(`⚠️ MySQL connection failed: ${err.message}`);
    console.warn('Continuing without a database connection so the backend can still start. Configure backend/.env or start MySQL to enable DB-backed features.');
  }
})();

module.exports = pool;
