'use strict';
const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const router = express.Router();
const SECRET = () => process.env.JWT_SECRET || 'dev-secret';

router.post('/register',
  body('username').trim().isLength({ min: 2, max: 50 }),
  body('password').isLength({ min: 6 }),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });
      const { username, password } = req.body;
      if (await User.findOne({ username })) return res.status(409).json({ error: 'Username taken' });
      const user = await User.create({ username, passwordHash: User.hashPassword(password) });
      const token = jwt.sign({ sub: user._id.toString(), username }, SECRET(), { expiresIn: '30d' });
      res.status(201).json({ token, username });
    } catch (e) { next(e); }
  },
);

router.post('/login',
  body('username').trim().notEmpty(),
  body('password').notEmpty(),
  async (req, res, next) => {
    try {
      const errs = validationResult(req);
      if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });
      const user = await User.findOne({ username: req.body.username });
      if (!user || !user.verifyPassword(req.body.password)) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
      const token = jwt.sign({ sub: user._id.toString(), username: user.username }, SECRET(), { expiresIn: '30d' });
      res.json({ token, username: user.username });
    } catch (e) { next(e); }
  },
);

module.exports = router;
