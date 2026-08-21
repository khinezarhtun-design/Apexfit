'use strict';
require('dotenv').config();
const express      = require('express');
const helmet       = require('helmet');
const cors         = require('cors');
const rateLimit    = require('express-rate-limit');
const { createProxyMiddleware, fixRequestBody } = require('http-proxy-middleware');
const express   = require('express');
const helmet    = require('helmet');
const cors      = require('cors');
const morgan    = require('morgan');
const rateLimit = require('express-rate-limit');

const dashboardRoutes = require('./routes/dashboard.routes');
const memberRoutes    = require('./routes/member.routes');
const staffRoutes     = require('./routes/staff.routes');
const auditRoutes     = require('./routes/audit.routes');
const healthRoutes    = require('./routes/health.routes');
const { errorHandler }   = require('./middleware/error.middleware');
const { auditLogger }    = require('./middleware/audit.middleware');
const logger = require('./config/logger');

const app = express();

app.set('trust proxy', 1);

app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*', credentials: true }));
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', { stream: { write: (m) => logger.info(m.trim()) } }));

// Health route — registered BEFORE rate limiter so kube probes are never throttled
app.use('/health',            healthRoutes);

app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 200, message: { success: false, error: 'Too many requests.' } }));

// Audit middleware — logs every mutating request made by staff/admin
app.use(auditLogger);
app.use('/api/v1/dashboard',  dashboardRoutes);
app.use('/api/v1/members',    memberRoutes);
app.use('/api/v1/staff',      staffRoutes);
app.use('/api/v1/audit',      auditRoutes);

<<<<<<< HEAD
  // Per-route rate limiter — disabled in development (port-forward funnels all
  // traffic through 127.0.0.1, which exhausts a shared bucket instantly).
  if (!isDev) {
    middlewareChain.push(rateLimit({
      windowMs: route.rateLimit.windowMs,
      max:      route.rateLimit.max,
      message:  { success: false, error: 'Too many requests, please try again later.' },
    }));
  }

  // JWT authentication (skip for public routes)
  if (!route.public) {
    middlewareChain.push(authenticate);
  }

  // Role-based authorization at gateway level (optional extra guard)
  if (route.roles?.length) {
    middlewareChain.push(authorize(...route.roles));
  }

  // Proxy to target service
  middlewareChain.push(
    createProxyMiddleware({
      target:      route.target,
      changeOrigin: true,
      pathRewrite: (path, req) => `${req.baseUrl}${path}`,
      on: {
        error: (err, req, res) => {
          logger.error(`[Gateway] Proxy error → ${route.target}: ${err.message} [${req.correlationId}]`);
          if (!res.headersSent) {
            res.status(503).json({ success: false, error: `Service at ${route.prefix} is unavailable.` });
          }
        },
        proxyReq: (proxyReq, req) => {
          // Re-stream parsed req.body to downstream service
          fixRequestBody(proxyReq, req);

          // Forward correlation ID and decoded user identity
          proxyReq.setHeader('X-Correlation-ID', req.correlationId || '');
          if (req.user) {
            proxyReq.setHeader('X-User-ID',   req.user.sub  || '');
            proxyReq.setHeader('X-User-Role',  req.user.role || '');
          }
        },
      },
    })
  );

  app.use(route.prefix, ...middlewareChain);
  logger.info(`[Gateway] Registered: ${route.prefix} → ${route.target}`);
});

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, error: `No route registered for ${req.method} ${req.originalUrl}` });
});

// ── Global error handler ──────────────────────────────────────────────────────
=======
app.use((req, res) => res.status(404).json({ success: false, error: `Route ${req.originalUrl} not found.` }));
>>>>>>> 9cd2946c5137c2a7495ffe03b1cfa41f2db4079b
app.use(errorHandler);

module.exports = app;
