'use strict';

const mongoose = require('mongoose');

// ── Attempt sub-document ─────────────────────────────────────────────────────
const attemptSchema = new mongoose.Schema(
  {
    evidenceType: {
      type: String,
      enum: ['text', 'screenshot', 'url', 'commit'],
      required: true,
    },
    evidenceValue: { type: String, required: true },
    evidenceHash: { type: String, required: true },
    verdict: {
      type: String,
      enum: ['pass', 'weak', 'fail', 'inconclusive'],
      required: true,
    },
    confidence: { type: Number, min: 0, max: 1, default: 0 },
    reasoning: { type: String, default: '' },
    message: { type: String, default: '' },
    flags: [{ type: String }],
    missing: [{ type: String }],
    usedAi: { type: Boolean, default: false },
  },
  { _id: true, timestamps: { createdAt: true, updatedAt: false } },
);

// ── Challenge sub-document ───────────────────────────────────────────────────
const challengeSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['typing', 'quiz', 'timer', 'explain', 'micro', 'cooldown'],
      required: true,
    },
    prompt: { type: String, required: true },
    seconds: { type: Number, default: 0 },
    dueAt: { type: Date },
    detail: { type: String, default: '' },
  },
  { _id: false },
);

// ── Task ─────────────────────────────────────────────────────────────────────
const taskSchema = new mongoose.Schema(
  {
    // ownership — optional when running without auth
    userId: { type: String, index: true },

    title: { type: String, required: true, trim: true, maxlength: 200 },
    definition: { type: String, default: '', trim: true, maxlength: 2000 },

    // Extended fields (competition requirements)
    deadline: { type: Date },
    priority: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' },
    acceptanceCriteria: { type: String, default: '', maxlength: 2000 },
    requiredEvidenceTypes: {
      type: [String],
      enum: ['text', 'screenshot', 'url', 'commit'],
      default: [],
    },
    expectedOutcome: { type: String, default: '', maxlength: 1000 },
    verificationPolicy: {
      type: String,
      enum: ['any', 'strict', 'ai_required'],
      default: 'any',
    },

    status: {
      type: String,
      enum: [
        'todo',
        'in_progress',
        'pending_verification',
        'needs_revision',
        'verified',
        'blocked',
        'done', // legacy compat with client
      ],
      default: 'todo',
    },

    challenge: { type: challengeSchema, default: null },
    attempts: [attemptSchema],
    completedAt: { type: Date },
  },
  { timestamps: true },
);

// Virtual: attempt count
taskSchema.virtual('attemptCount').get(function () {
  return this.attempts.length;
});

// Helper: is task in a terminal state?
taskSchema.virtual('isDone').get(function () {
  return this.status === 'done' || this.status === 'verified';
});

taskSchema.virtual('isLocked').get(function () {
  return this.challenge != null;
});

taskSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Task', taskSchema);
