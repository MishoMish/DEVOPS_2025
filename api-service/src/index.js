const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Database connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'devopsdb',
  user: process.env.DB_USER || 'devops',
  password: process.env.DB_PASSWORD || 'devops123',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Track if database is connected
let dbConnected = false;

// Initialize database connection
async function initDB() {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    dbConnected = true;
    console.log('✅ Database connected successfully');
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    dbConnected = false;
  }
}

// Health check endpoint
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    database: dbConnected ? 'connected' : 'disconnected'
  };
  
  // Try to ping database
  if (dbConnected) {
    try {
      await pool.query('SELECT 1');
      health.database = 'connected';
    } catch {
      health.database = 'disconnected';
    }
  }
  
  res.status(200).json(health);
});

// Main API endpoint - now with visitor tracking
app.get('/api/hello', async (req, res) => {
  let visitorCount = 0;
  let dbStatus = 'disconnected';
  
  if (dbConnected) {
    try {
      // Record this visit
      await pool.query(
        'INSERT INTO visitors (ip_address, user_agent, path) VALUES ($1, $2, $3)',
        [req.ip || 'unknown', req.get('User-Agent') || 'unknown', '/api/hello']
      );
      
      // Update and get total count
      await pool.query(
        'UPDATE visitor_stats SET stat_value = stat_value + 1, updated_at = CURRENT_TIMESTAMP WHERE stat_name = $1',
        ['total_visits']
      );
      
      const result = await pool.query(
        'SELECT stat_value FROM visitor_stats WHERE stat_name = $1',
        ['total_visits']
      );
      
      visitorCount = result.rows[0]?.stat_value || 0;
      dbStatus = 'connected';
    } catch (err) {
      console.error('Database error:', err.message);
      dbStatus = 'error';
    }
  }
  
  res.status(200).json({
    message: 'Hello from the API 🎉',
    visitors: visitorCount,
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});

// Get visitor statistics
app.get('/api/stats', async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ 
      error: 'Database not connected',
      stats: null 
    });
  }
  
  try {
    const totalVisits = await pool.query(
      'SELECT stat_value FROM visitor_stats WHERE stat_name = $1',
      ['total_visits']
    );
    
    const recentVisitors = await pool.query(
      'SELECT COUNT(*) as count FROM visitors WHERE visited_at > NOW() - INTERVAL \'24 hours\''
    );
    
    const messageCount = await pool.query('SELECT COUNT(*) as count FROM messages');
    
    res.status(200).json({
      stats: {
        totalVisits: parseInt(totalVisits.rows[0]?.stat_value || 0),
        last24Hours: parseInt(recentVisitors.rows[0]?.count || 0),
        messageCount: parseInt(messageCount.rows[0]?.count || 0)
      },
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Stats error:', err.message);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// Get messages (guestbook)
app.get('/api/messages', async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ 
      error: 'Database not connected',
      messages: [] 
    });
  }
  
  try {
    const result = await pool.query(
      'SELECT id, author, content, created_at FROM messages ORDER BY created_at DESC LIMIT 10'
    );
    
    res.status(200).json({
      messages: result.rows,
      database: 'connected'
    });
  } catch (err) {
    console.error('Messages error:', err.message);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Post a new message
app.post('/api/messages', async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ error: 'Database not connected' });
  }
  
  const { author, content } = req.body;
  
  if (!content || content.trim().length === 0) {
    return res.status(400).json({ error: 'Message content is required' });
  }
  
  // Sanitize input (basic XSS prevention)
  const sanitizedAuthor = (author || 'Anonymous').substring(0, 100).replace(/<[^>]*>/g, '');
  const sanitizedContent = content.substring(0, 500).replace(/<[^>]*>/g, '');
  
  try {
    const result = await pool.query(
      'INSERT INTO messages (author, content) VALUES ($1, $2) RETURNING id, author, content, created_at',
      [sanitizedAuthor, sanitizedContent]
    );
    
    res.status(201).json({
      message: 'Message created',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Create message error:', err.message);
    res.status(500).json({ error: 'Failed to create message' });
  }
});

// Database info endpoint (for demo purposes)
app.get('/api/db-info', async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ 
      connected: false,
      error: 'Database not connected'
    });
  }
  
  try {
    const versionResult = await pool.query('SELECT version()');
    const tablesResult = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    );
    
    res.status(200).json({
      connected: true,
      version: versionResult.rows[0]?.version?.split(' ').slice(0, 2).join(' '),
      tables: tablesResult.rows.map(r => r.table_name),
      host: process.env.DB_HOST || 'localhost'
    });
  } catch (err) {
    console.error('DB info error:', err.message);
    res.status(500).json({ error: 'Failed to get DB info' });
  }
});

// Start server only if not in test environment
if (process.env.NODE_ENV !== 'test') {
  initDB().then(() => {
    app.listen(PORT, () => {
      console.log(`API service running on port ${PORT}`);
    });
  });
}

module.exports = { app, pool, initDB };
