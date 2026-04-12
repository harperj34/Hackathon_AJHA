const { getPool } = require('../../db');

// GET /api/user/:email — check whether email already exists
module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const email = (req.query.email ?? '').toLowerCase();
  if (!email) return res.status(400).json({ error: 'Email is required' });

  const pool = getPool();
  try {
    const result = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    return res.json({ exists: result.rows.length > 0 });
  } catch (err) {
    console.error('Error checking email:', err.message);
    return res.status(500).json({ error: 'Database error' });
  }
};
