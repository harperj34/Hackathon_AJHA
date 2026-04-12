const { getPool } = require('../db');

// POST /api/user — create a new user
module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { email } = req.body ?? {};
  if (!email) return res.status(400).json({ error: 'Email is required' });

  const pool = getPool();
  try {
    await pool.query(
      'INSERT INTO users (email) VALUES ($1)',
      [email.toLowerCase()]
    );
    return res.json({ success: true });
  } catch (err) {
    if (err.code === '23505') {
      return res.json({ success: true, note: 'Email already exists' });
    }
    console.error('Error creating user:', err.message);
    return res.status(500).json({ error: 'Database error' });
  }
};
