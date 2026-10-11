'use strict';

require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');

const taskRouter = require('./routes/tasks');
const verifyRouter = require('./routes/verify');
const authRouter = require('./routes/auth');
const { errorHandler } = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 5000;

// ── security ────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(
  cors({
    origin: (process.env.CLIENT_ORIGIN || 'http://localhost:8080')
      .split(',')
      .map((o) => o.trim()),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);

// Global rate limiter — tighten per-route where needed
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 120,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests. Slow down.' },
  }),
);

app.use(express.json({ limit: '10mb' })); // screenshots arrive as base64

// ── routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth', authRouter);
app.use('/api/tasks', taskRouter);
app.use('/api/verify', verifyRouter);

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

// ── error handler ────────────────────────────────────────────────────────────
app.use(errorHandler);

// ── database + start ─────────────────────────────────────────────────────────
async function start() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI is not set. Check your .env file.');
    process.exit(1);
  }
  await mongoose.connect(uri);
  console.log('MongoDB connected');
  app.listen(PORT, () => console.log(`ProofTask backend listening on :${PORT}`));
}

start().catch((err) => {
  console.error('Startup failed:', err);
  process.exit(1);
});

module.exports = app; // for tests
