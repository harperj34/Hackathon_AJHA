const { getPool } = require('./db');

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const pool = getPool();

  // GET /api/signals — fetch all visible, non-expired signals
  if (req.method === 'GET') {
    try {
      const result = await pool.query(
        `SELECT * FROM signals
         WHERE visible = true
           AND lat IS NOT NULL AND lng IS NOT NULL
           AND created_at + (duration_minutes * INTERVAL '1 minute') > now()
         ORDER BY created_at DESC`
      );
      return res.json({ signals: result.rows });
    } catch (err) {
      console.error('Error fetching signals:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
  }

  // POST /api/signals — save a new signal
  if (req.method === 'POST') {
    const {
      id, title, subtitle, location, display_time,
      duration_minutes, image_url, category,
      lat, lng, attendees, is_seed, created_by, visible,
    } = req.body ?? {};

    try {
      await pool.query(
        `INSERT INTO signals
           (id, title, subtitle, location, display_time,
            duration_minutes, image_url, category, lat, lng,
            attendees, is_seed, created_by, visible)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
        [
          id,
          title,
          subtitle ?? '',
          location ?? '',
          display_time ?? '',
          duration_minutes ?? 30,
          image_url ?? '',
          category,
          lat,
          lng,
          attendees ?? 0,
          is_seed ?? false,
          created_by ?? '',
          visible !== false,
        ]
      );
      return res.json({ success: true });
    } catch (err) {
      if (err.code === '23505') {
        return res.json({ success: true, note: 'Already exists' });
      }
      console.error('Error saving signal:', err.message);
      return res.status(500).json({ error: 'Database error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
