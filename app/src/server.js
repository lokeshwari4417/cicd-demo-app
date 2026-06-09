const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const APP_VERSION = process.env.APP_VERSION || '1.0.0';
const ENVIRONMENT = process.env.NODE_ENV || 'development';

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Request logger middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.url} - IP: ${req.ip}`);
  next();
});

// Health check endpoint (used by CI/CD and monitoring)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    version: APP_VERSION,
    environment: ENVIRONMENT,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    hostname: os.hostname()
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    app: 'DevOps Demo App',
    version: APP_VERSION,
    environment: ENVIRONMENT,
    node_version: process.version,
    platform: os.platform(),
    hostname: os.hostname(),
    memory: {
      total: Math.round(os.totalmem() / 1024 / 1024) + ' MB',
      free: Math.round(os.freemem() / 1024 / 1024) + ' MB'
    }
  });
});

// API metrics endpoint (basic monitoring)
app.get('/api/metrics', (req, res) => {
  const uptimeSeconds = process.uptime();
  res.json({
    uptime_seconds: Math.floor(uptimeSeconds),
    uptime_human: formatUptime(uptimeSeconds),
    memory_usage: process.memoryUsage(),
    cpu_usage: process.cpuUsage(),
    node_version: process.version,
    timestamp: new Date().toISOString()
  });
});

// Root route - serve the main HTML page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${err.message}`);
  res.status(500).json({ error: 'Internal server error' });
});

// Helper: format uptime
function formatUptime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return `${h}h ${m}m ${s}s`;
}

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`====================================`);
  console.log(` DevOps Demo App v${APP_VERSION}`);
  console.log(` Environment : ${ENVIRONMENT}`);
  console.log(` Port        : ${PORT}`);
  console.log(` Started     : ${new Date().toISOString()}`);
  console.log(`====================================`);
});

module.exports = app;
