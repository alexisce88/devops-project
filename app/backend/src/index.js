const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'changeme',
});

// Initialize DB table on startup
async function initDb() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    // Seed with sample data if empty
    const { rowCount } = await pool.query('SELECT COUNT(*) FROM items');
    if (rowCount === 0 || (await pool.query('SELECT COUNT(*) FROM items')).rows[0].count === '0') {
      await pool.query(`
        INSERT INTO items (name) VALUES
        ('Item Alpha'), ('Item Beta'), ('Item Gamma')
        ON CONFLICT DO NOTHING
      `);
    }
    console.log('Database initialized');
  } catch (err) {
    console.error('DB init error (retrying in 5s):', err.message);
    setTimeout(initDb, 5000);
  }
}

// GET /health — liveness probe
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: process.env.IMAGE_TAG || 'dev',
    env: process.env.NODE_ENV || 'development',
  });
});

// GET /status — readiness probe (checks DB)
app.get('/status', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'ready', db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'not ready', db: 'disconnected', error: err.message });
  }
});

// GET /items — list all items
app.get('/items', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM items ORDER BY id');
    res.status(200).json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch items', details: err.message });
  }
});

// POST /items — create a new item
app.post('/items', async (req, res) => {
  const { name } = req.body;
  if (!name || typeof name !== 'string' || name.trim() === '') {
    return res.status(400).json({ error: 'Field "name" is required and must be a non-empty string' });
  }
  try {
    const result = await pool.query(
      'INSERT INTO items (name) VALUES ($1) RETURNING *',
      [name.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to create item', details: err.message });
  }
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend running on port ${PORT}`);
  initDb();
});

module.exports = { app, server, pool };
