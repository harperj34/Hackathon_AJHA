const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

//allow flutter web to talk to server
app.use(cors());
app.use(express.json());

//connect to neon db
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

//test connection with neon db
pool.connect((err) => {
  if (err) {
    console.error('Failed to connect to database:', err.message);
  } else {
    console.log('Connected to Neon database successfully!');
  }
});

// ── ROUTES ──────────────────────────────────────────────────────────────────

//check if email exists
// Flutter calls this to decide "login" vs "create account"
app.get('/user/:email', async (req, res) => {
  const email = req.params.email.toLowerCase();
  try {
    const result = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    res.json({ exists: result.rows.length > 0 });
  } catch (err) {
    console.error('Error checking email:', err.message);
    res.status(500).json({ error: 'Database error' });
  }
});

//New user
// Flutter calls this when the email doesn't exist yet
app.post('/user', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }
  try {
    await pool.query(
      'INSERT INTO users (email) VALUES ($1)',
      [email.toLowerCase()]
    );
    res.json({ success: true });
  } catch (err) {
    //duplicate email
    if (err.code === '23505') {
      res.json({ success: true, note: 'Email already exists' });
    } else {
      console.error('Error creating user:', err.message);
      res.status(500).json({ error: 'Database error' });
    }
  }
});

// ── START SERVER ─────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://localhost:${PORT}`);
});