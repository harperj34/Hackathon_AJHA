const { getPool } = require('../db');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const pool = getPool();
  const { id } = req.query;

  // PATCH /api/signals/:id — mark a signal as no longer visible
  if (req.method === 'PATCH') {
    try {
      await pool.query(
        `UPDATE signals SET visible = false WHERE id = $1`,
        [id]
      );
      return res.json({ success: true });
    } catch (err) {
      console.error('Error hiding signal:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
