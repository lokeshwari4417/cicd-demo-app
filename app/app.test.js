const request = require('supertest');
const app = require('./src/server');

describe('CI/CD Demo App - API Tests', () => {

  // Test 1: Health check endpoint
  test('GET /health - returns healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('status', 'healthy');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('uptime');
  });

  // Test 2: API info endpoint
  test('GET /api/info - returns app info', async () => {
    const res = await request(app).get('/api/info');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('app');
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('node_version');
    expect(res.body).toHaveProperty('platform');
  });

  // Test 3: Metrics endpoint
  test('GET /api/metrics - returns metrics object', async () => {
    const res = await request(app).get('/api/metrics');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('uptime_seconds');
    expect(res.body).toHaveProperty('memory_usage');
    expect(typeof res.body.uptime_seconds).toBe('number');
  });

  // Test 4: Root page serves HTML
  test('GET / - serves HTML page', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
  });

  // Test 5: 404 for unknown routes
  test('GET /nonexistent - returns 404', async () => {
    const res = await request(app).get('/nonexistent-route-xyz');
    expect(res.statusCode).toBe(404);
  });

  // Test 6: Health check has correct structure
  test('GET /health - response has all required fields', async () => {
    const res = await request(app).get('/health');
    const requiredFields = ['status', 'version', 'environment', 'timestamp', 'uptime', 'hostname'];
    requiredFields.forEach(field => {
      expect(res.body).toHaveProperty(field);
    });
  });

  // Test 7: API info has memory details
  test('GET /api/info - includes memory info', async () => {
    const res = await request(app).get('/api/info');
    expect(res.body).toHaveProperty('memory');
    expect(res.body.memory).toHaveProperty('total');
    expect(res.body.memory).toHaveProperty('free');
  });

});
