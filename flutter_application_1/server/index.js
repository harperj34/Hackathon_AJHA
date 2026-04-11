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

// GET /events — fetch all events from DB
app.get('/events', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM events ORDER BY created_at DESC');
    res.json({ events: result.rows });
  } catch (err) {
    console.error('Error fetching events:', err.message);
    res.status(500).json({ error: 'Database error' });
  }
});

// POST /events — save a new user-created event
app.post('/events', async (req, res) => {
  const {
    id, title, subtitle, location, display_time,
    duration_minutes, image_url, category,
    lat, lng, attendees, is_seed
  } = req.body;

  try {
    await pool.query(
      `INSERT INTO events 
        (id, title, subtitle, location, display_time, duration_minutes, image_url, category, lat, lng, attendees, is_seed)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      [
        id, title, subtitle, location, display_time,
        duration_minutes ?? 60,
        image_url ?? '',
        category, lat, lng,
        attendees ?? 0,
        is_seed ?? false
      ]
    );
    res.json({ success: true });
  } catch (err) {
    if (err.code === '23505') {
      res.json({ success: true, note: 'Already exists' });
    } else {
      console.error('Error saving event:', err.message);
      res.status(500).json({ error: 'Database error' });
    }
  }
});

// ── START SERVER ─────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  console.log('Server running at http://localhost:3000');
});

