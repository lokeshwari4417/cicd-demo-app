// DevOps CI/CD Demo - Frontend JS

// Animate pipeline steps on load
document.addEventListener('DOMContentLoaded', () => {
  const steps = document.querySelectorAll('.pipe-step');
  steps.forEach((step, i) => {
    step.style.opacity = '0.2';
    setTimeout(() => {
      step.classList.add('active');
      step.style.opacity = '';
    }, 300 + i * 300);
  });

  loadMetrics();
});

// Load live metrics from /health endpoint
async function loadMetrics() {
  const fields = {
    'metric-status': '—',
    'metric-version': '—',
    'metric-env': '—',
    'metric-uptime': '—',
    'metric-host': '—',
    'metric-time': '—'
  };

  // Reset to loading state
  Object.keys(fields).forEach(id => {
    const el = document.getElementById(id);
    if (el) el.textContent = 'Loading...';
  });

  try {
    const res = await fetch('/health');
    const data = await res.json();

    document.getElementById('metric-status').textContent = data.status === 'healthy' ? '✅ Healthy' : '❌ Unhealthy';
    document.getElementById('metric-version').textContent = data.version || '—';
    document.getElementById('metric-env').textContent = data.environment || '—';
    document.getElementById('metric-uptime').textContent = formatUptime(data.uptime || 0);
    document.getElementById('metric-host').textContent = data.hostname || '—';
    document.getElementById('metric-time').textContent = new Date(data.timestamp).toLocaleTimeString();

    // Color status green
    const statusEl = document.getElementById('metric-status');
    statusEl.style.color = data.status === 'healthy' ? '#3fb950' : '#f78166';
  } catch (err) {
    document.getElementById('metric-status').textContent = '❌ Unreachable';
    document.getElementById('metric-status').style.color = '#f78166';
    console.error('Failed to load metrics:', err);
  }
}

function formatUptime(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return `${h}h ${m}m ${s}s`;
}

// Auto-refresh metrics every 30 seconds
setInterval(loadMetrics, 30000);
