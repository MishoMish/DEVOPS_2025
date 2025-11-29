const request = require('supertest');
const app = require('../src/index');

describe('API Service Tests', () => {
  test('GET /health returns 200 and healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  test('GET /api/hello returns 200 and greeting message', async () => {
    const response = await request(app).get('/api/hello');
    expect(response.status).toBe(200);
    expect(response.body.message).toBe('Hello from the API 🎉');
  });
});
