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

// ── EMERGENCY CRASH CATCHERS (Prevents process exit on unhandled errors) ──
process.on('uncaughtException', (err) => {
  console.error('[CRITICAL] Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('[CRITICAL] Unhandled Rejection at:', promise, 'reason:', reason);
});
 (fix(api-gateway): prevent 502 crash loops with safe proxy error handler)

require('dotenv').config();
const express      = require('express');
const helmet       = require('helmet');
const cors         = require('cors');
const rateLimit    = require('express-rate-limit');
const { createProxyMiddleware, fixRequestBody } = require('http-proxy-middleware');

const routes       = require('./config/routes');
const logger       = require('./config/logger');
const { authenticate, authorize } = require('./middleware/auth.middleware');
const { correlationId, requestLogger } = require('./middleware/correlation.middleware');
const { errorHandler } = require('./middleware/error.middleware');

const app = express();

// Respect the single reverse proxy hop used by Docker/K8s ingress so
// express-rate-limit can safely consume X-Forwarded-For.
app.set('trust proxy', 1);

// ── Global middleware ─────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  exposedHeaders: ['X-Correlation-ID'],
}));
app.use(correlationId);
app.use(requestLogger);
app.use(express.json({ limit: '10kb' }));

// ── Health endpoint (no proxy — handled by gateway itself) ────────────────────
app.use('/health', require('./routes/health.routes'));

// ── Dynamically register proxy routes from routing table ──────────────────────
const isDev = (process.env.NODE_ENV || 'development') === 'development';

routes.forEach((route) => {
  const middlewareChain = [];

 (fix(api-gateway): prevent 502 crash loops with safe proxy error handler)
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
          try {
            if (res && typeof res.headersSent === 'boolean' && !res.headersSent && !res.writableEnded) {
              res.status(503).json({ success: false, error: `Service at ${route.prefix} is unavailable.` });
            }
          } catch (e) {
            logger.error(`[Gateway] Failed to handle proxy error response: ${e.message}`);
 (fix(api-gateway): prevent 502 crash loops with safe proxy error handler)
          }
        },
        proxyReq: (proxyReq, req) => {
          // Re-stream parsed req.body to downstream service
          fixRequestBody(proxyReq, req);

          // Forward correlation ID and decoded user identity
          proxyReq.setHeader('X-Correlation-ID', req.correlationId || '');
          if (req.user) {

            proxyReq.setHeader('X-User-ID',   req.user.sub  || '');

            proxyReq.setHeader('X-User-ID',    req.user.sub  || '');
 (fix(api-gateway): prevent 502 crash loops with safe proxy error handler)
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
app.use((req, res) => res.status(404).json({ success: false, error: `Route ${req.originalUrl} not found.` }));
 9cd2946c5137c2a7495ffe03b1cfa41f2db4079b
 (fix(api-gateway): prevent 502 crash loops with safe proxy error handler)
app.use(errorHandler);

module.exports = app;
