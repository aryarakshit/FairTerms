const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000,http://127.0.0.1:3000,http://localhost:5000,http://127.0.0.1:5000')
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);

function validateCorsOrigin(origin, callback) {
  if (!origin) return callback(null, true); // non-browser / same-origin

  // In non-production, allow all localhost origins regardless of port
  // (Flutter web dev server picks a random port)
  if (process.env.NODE_ENV !== 'production') {
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
      return callback(null, true);
    }
  }

  if (allowedOrigins.includes(origin)) return callback(null, true);

  const error = new Error('CORS_NOT_ALLOWED');
  error.status = 403;
  return callback(error);
}

// Middleware
app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin: validateCorsOrigin,
  optionsSuccessStatus: 204,
}));
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT || '50kb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

// Routes
const smeRoutes = require('./routes/sme.routes');
const analysisRoutes = require('./routes/analysis.routes');
const benchmarkRoutes = require('./routes/benchmark.routes');
const heatmapRoutes = require('./routes/heatmap.routes');
const leaderboardRoutes = require('./routes/leaderboard.routes');
const adminRoutes = require('./routes/admin.routes');

app.use('/api/v1/sme', smeRoutes);
app.use('/api/v1/analysis', analysisRoutes);
app.use('/api/v1/benchmark', benchmarkRoutes);
app.use('/api/v1/heatmap', heatmapRoutes);
app.use('/api/v1/leaderboard', leaderboardRoutes);
app.use('/api/v1/admin', adminRoutes);

// Health check
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ success: true, data: { status: 'OK' } });
});

// 404 — must be placed after all routes
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'NotFound', path: req.path });
});

// Error handling middleware
app.use((err, req, res, next) => {
  if (err.status === 403 && err.message === 'CORS_NOT_ALLOWED') {
    return res.status(403).json({
      success: false,
      error: 'FORBIDDEN',
      message: 'Origin is not allowed'
    });
  }

  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    error: 'INTERNAL_ERROR',
    message: process.env.NODE_ENV === 'development' ? err.message : 'An unexpected error occurred',
    requestId: req.headers['x-request-id'] || null,
  });
});

// Start server
if (require.main === module) {
  app.listen(port, () => {
    console.log(`FairTerms Backend API listening on port ${port}`);
  });
}

module.exports = app;
