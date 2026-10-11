'use strict';

const mongoose = require('mongoose');
const crypto = require('crypto');

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      minlength: 2,
      maxlength: 50,
    },
    // Stored as: salt:hash — never plaintext
    passwordHash: { type: String, required: true },
    roastLevel: { type: Number, default: 1, min: 0, max: 3 },
    strictness: { type: Number, default: 1, min: 0, max: 3 },
    notToday: { type: Boolean, default: false },
  },
  { timestamps: true },
);

// Hash password with PBKDF2
userSchema.statics.hashPassword = function (plain) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto
    .pbkdf2Sync(plain, salt, 310000, 32, 'sha256')
    .toString('hex');
  return `${salt}:${hash}`;
};

userSchema.methods.verifyPassword = function (plain) {
  const [salt, stored] = this.passwordHash.split(':');
  const attempt = crypto
    .pbkdf2Sync(plain, salt, 310000, 32, 'sha256')
    .toString('hex');
  return crypto.timingSafeEqual(Buffer.from(stored, 'hex'), Buffer.from(attempt, 'hex'));
};

module.exports = mongoose.model('User', userSchema);
