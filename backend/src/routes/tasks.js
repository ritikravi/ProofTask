'use strict';
const express = require('express');
const { body, validationResult } = require('express-validator');
const Task = require('../models/Task');
const { softAuth } = require('../middleware/auth');

const router = express.Router();
router.use(softAuth);

// scope helper — tasks belong to user if authed, else anonymous bucket
function scope(req) {
  return req.user ? { userId: req.user.sub } : { userId: null };
}

// GET /api/tasks
router.get('/', async (req, res, next) => {
  try {
    const tasks = await Task.find(scope(req)).sort({ createdAt: -1 }).lean({ virtuals: true });
    res.json(tasks);
  } catch (e) { next(e); }
});

// POST /api/tasks
router.post('/',
  body('title').trim().isLength({ min: 3, max: 200 }),
  body('definition').optional().trim().isLength({ max: 2000 }),
  body('deadline').optional().isISO8601(),
  body('priority').optional().isIn(['low', 'medium', 'high']),
  body('acceptanceCriteria').optional().trim().isLength({ max: 2000 }),
  body('requiredEvidenceTypes').optional().isArray(),
  body('expectedOutcome').optional().trim().isLength({ max: 1000 }),
  body('verificationPolicy').optional().isIn(['any', 'strict', 'ai_required']),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });
      const task = await Task.create({ ...req.body, ...scope(req) });
      res.status(201).json(task.toJSON());
    } catch (e) { next(e); }
  },
);

// GET /api/tasks/:id
router.get('/:id', async (req, res, next) => {
  try {
    const task = await Task.findOne({ _id: req.params.id, ...scope(req) }).lean({ virtuals: true });
    if (!task) return res.status(404).json({ error: 'Not found' });
    res.json(task);
  } catch (e) { next(e); }
});

// PATCH /api/tasks/:id  (update title/definition/deadline/priority/status etc.)
router.patch('/:id',
  body('title').optional().trim().isLength({ min: 3, max: 200 }),
  body('status').optional().isIn(['todo','in_progress','pending_verification','needs_revision','verified','blocked','done']),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });
      const allowed = ['title','definition','deadline','priority','acceptanceCriteria','requiredEvidenceTypes','expectedOutcome','verificationPolicy','status'];
      const updates = Object.fromEntries(Object.entries(req.body).filter(([k]) => allowed.includes(k)));
      const task = await Task.findOneAndUpdate(
        { _id: req.params.id, ...scope(req) },
        { $set: updates },
        { new: true, runValidators: true },
      ).lean({ virtuals: true });
      if (!task) return res.status(404).json({ error: 'Not found' });
      res.json(task);
    } catch (e) { next(e); }
  },
);

// DELETE /api/tasks/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const task = await Task.findOneAndDelete({ _id: req.params.id, ...scope(req) });
    if (!task) return res.status(404).json({ error: 'Not found' });
    res.json({ deleted: true });
  } catch (e) { next(e); }
});

// POST /api/tasks/:id/challenge/clear
router.post('/:id/challenge/clear', async (req, res, next) => {
  try {
    const task = await Task.findOneAndUpdate(
      { _id: req.params.id, ...scope(req) },
      { $set: { challenge: null } },
      { new: true },
    ).lean({ virtuals: true });
    if (!task) return res.status(404).json({ error: 'Not found' });
    res.json(task);
  } catch (e) { next(e); }
});

// POST /api/tasks/:id/subtasks  { titles: string[] }
router.post('/:id/subtasks',
  body('titles').isArray({ min: 1 }),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });
      const parent = await Task.findOne({ _id: req.params.id, ...scope(req) });
      if (!parent) return res.status(404).json({ error: 'Not found' });
      const now = new Date();
      const subs = await Task.insertMany(
        req.body.titles.map((t) => ({
          title: String(t).trim(),
          definition: `Part of: ${parent.title}`,
          createdAt: now,
          ...scope(req),
        })),
      );
      // Unlock parent
      parent.challenge = null;
      await parent.save();
      res.status(201).json({ parent: parent.toJSON(), subtasks: subs.map((s) => s.toJSON()) });
    } catch (e) { next(e); }
  },
);

module.exports = router;
