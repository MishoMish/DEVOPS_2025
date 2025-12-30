const request = require('supertest');
const { app } = require('../src/index');

describe('API Service Tests', () => {
  test('GET /health returns 200 and healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('database');
  });

  test('GET /api/hello returns 200 and greeting message', async () => {
    const response = await request(app).get('/api/hello');
    expect(response.status).toBe(200);
    expect(response.body.message).toBe('Hello from the API 🎉');
    expect(response.body).toHaveProperty('visitors');
    expect(response.body).toHaveProperty('database');
    expect(response.body).toHaveProperty('timestamp');
  });

  test('GET /api/stats returns stats or error when DB not connected', async () => {
    const response = await request(app).get('/api/stats');
    // Either 200 with stats or 503 when DB not connected
    expect([200, 503]).toContain(response.status);
    if (response.status === 200) {
      expect(response.body).toHaveProperty('stats');
    } else {
      expect(response.body).toHaveProperty('error');
    }
  });

  test('GET /api/messages returns messages array or error', async () => {
    const response = await request(app).get('/api/messages');
    expect([200, 503]).toContain(response.status);
    if (response.status === 200) {
      expect(response.body).toHaveProperty('messages');
      expect(Array.isArray(response.body.messages)).toBe(true);
    }
  });

  test('POST /api/messages requires content', async () => {
    const response = await request(app)
      .post('/api/messages')
      .send({ author: 'Test' })
      .set('Content-Type', 'application/json');
    
    // Either 400 (validation error) or 503 (DB not connected)
    expect([400, 503]).toContain(response.status);
  });

  test('GET /api/db-info returns database info', async () => {
    const response = await request(app).get('/api/db-info');
    expect([200, 503]).toContain(response.status);
    expect(response.body).toHaveProperty('connected');
  });
});
