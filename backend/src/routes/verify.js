'use strict';
const express = require('express');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const Task = require('../models/Task');
const VerificationService = require('../services/verificationService');
const { generateChallenge, failedCount } = require('../services/challengeGenerator');
const { softAuth } = require('../middleware/auth');

const router = express.Router();
router.use(softAuth);

// Tighter rate limit for AI calls
const aiLimit = rateLimit({ windowMs: 60_000, max: 30, message: { error: 'AI rate limit. Wait a moment.' } });

function scope(req) {
  return req.user ? { userId: req.user.sub } : { userId: null };
}

function makeService(req) {
  return new VerificationService({
    strictness: Number(req.body.strictness ?? 1),
    roastLevel: Number(req.body.roastLevel ?? 1),
    notToday: req.body.notToday === true,
    githubToken: process.env.GITHUB_TOKEN || '',
  });
}

/**
 * POST /api/verify/:taskId/submit
 * Body: { evidenceType, evidenceValue, evidenceBase64?, evidenceMime?, strictness?, roastLevel?, notToday? }
 */
router.post('/:taskId/submit', aiLimit,
  body('evidenceType').isIn(['text', 'screenshot', 'url', 'commit']),
  body('evidenceValue').isString(),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

      const task = await Task.findOne({ _id: req.params.taskId, ...scope(req) });
      if (!task) return res.status(404).json({ error: 'Task not found' });
      if (task.isDone) return res.status(409).json({ error: 'Task already verified' });
      if (task.isLocked) return res.status(409).json({ error: 'Task locked — clear challenge first' });

      const evidence = {
        type: req.body.evidenceType,
        value: req.body.evidenceValue || '',
        mime: req.body.evidenceMime || 'image/jpeg',
        bytes: req.body.evidenceBase64 ? Buffer.from(req.body.evidenceBase64, 'base64') : null,
      };

      const svc = makeService(req);
      const outcome = await svc.submit(task, evidence);

      // Save attempt
      task.attempts.push({
        evidenceType: evidence.type,
        evidenceValue: evidence.type === 'screenshot' ? '[image]' : evidence.value,
        evidenceHash: outcome.hash,
        verdict: outcome.verdict,
        confidence: outcome.confidence,
        reasoning: outcome.reasoning,
        message: outcome.message,
        flags: outcome.flags,
        missing: outcome.missing,
        usedAi: outcome.usedAi,
      });

      if (outcome.verdict === 'pass') {
        task.status = 'verified';
        task.completedAt = new Date();
        task.challenge = null;
      } else if (outcome.verdict !== 'inconclusive') {
        const fc = failedCount(task);
        task.challenge = generateChallenge(fc, new Date(), Date.now());
        task.status = 'needs_revision';
      }
      // inconclusive → no penalty, status unchanged

      await task.save();
      res.json({ outcome, task: task.toJSON() });
    } catch (e) { next(e); }
  },
);

/**
 * POST /api/verify/:taskId/dispute
 * Body: { originalText, note, strictness?, roastLevel?, notToday? }
 */
router.post('/:taskId/dispute', aiLimit,
  body('originalText').isString().isLength({ min: 1 }),
  body('note').isString().isLength({ min: 15 }),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

      const task = await Task.findOne({ _id: req.params.taskId, ...scope(req) });
      if (!task) return res.status(404).json({ error: 'Task not found' });

      const svc = makeService(req);
      const outcome = await svc.dispute(task, req.body.originalText, req.body.note);

      // Update last attempt verdict
      if (task.attempts.length > 0) {
        const last = task.attempts[task.attempts.length - 1];
        last.verdict = outcome.verdict;
        last.confidence = outcome.confidence;
        last.reasoning = `Disputed. ${outcome.reasoning}`;
        last.message = outcome.message;
      }

      if (outcome.verdict === 'pass') {
        task.status = 'verified';
        task.completedAt = new Date();
        task.challenge = null;
      }
      await task.save();
      res.json({ outcome, task: task.toJSON() });
    } catch (e) { next(e); }
  },
);

module.exports = router;
