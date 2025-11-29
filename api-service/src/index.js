const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Main API endpoint
app.get('/api/hello', (req, res) => {
  res.status(200).json({ message: 'Hello from the API 🎉' });
});

// Start server only if not in test environment
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`API service running on port ${PORT}`);
  });
}

module.exports = app;
