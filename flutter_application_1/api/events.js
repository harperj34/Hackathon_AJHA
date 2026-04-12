const { getPool } = require('./db');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const pool = getPool();

  // GET /api/events — fetch all events with valid coordinates
  if (req.method === 'GET') {
    try {
      const result = await pool.query(
        `SELECT * FROM events
         WHERE lat IS NOT NULL AND lng IS NOT NULL
         ORDER BY created_at DESC`
      );
      return res.json({ events: result.rows });
    } catch (err) {
      console.error('Error fetching events:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
  }

  // POST /api/events — save a new event
  if (req.method === 'POST') {
    const {
      id, title, subtitle, location, display_time,
      duration_minutes, image_url, category,
      lat, lng, attendees, is_seed,
    } = req.body ?? {};

    try {
      await pool.query(
        `INSERT INTO events
           (id, title, subtitle, location, display_time,
            duration_minutes, image_url, category, lat, lng, attendees, is_seed)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
        [
          id, title, subtitle, location, display_time,
          duration_minutes ?? 60,
          image_url ?? '',
          category, lat, lng,
          attendees ?? 0,
          is_seed ?? false,
        ]
      );
      return res.json({ success: true });
    } catch (err) {
      if (err.code === '23505') {
        return res.json({ success: true, note: 'Already exists' });
      }
      console.error('Error saving event:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
