'use strict';

const PLEDGE =
  'I will provide real proof of real work and stop pretending that a vague sentence counts as evidence.';

const MICRO_TASKS = [
  'Do 10 squats.',
  'Drink a full glass of water.',
  'Stand up and stretch for 30 seconds.',
  'Take 10 slow, deep breaths.',
  'Walk to another room and back.',
];

/**
 * Escalating challenge ladder — matches Flutter challenge_generator.dart.
 * @param {number} failedAttempts
 * @param {Date}   now
 * @param {number} seed
 */
function generateChallenge(failedAttempts, now = new Date(), seed = 0) {
  if (failedAttempts <= 1) {
    return { type: 'typing', prompt: PLEDGE, seconds: 0, detail: '' };
  }
  if (failedAttempts === 2) {
    return { type: 'quiz', prompt: 'Three quick questions about your own task.', seconds: 0, detail: '' };
  }
  if (failedAttempts === 3) {
    return {
      type: 'timer',
      prompt: 'Hold still for 45 seconds. Leave the app and the clock restarts.',
      seconds: 45,
      detail: '',
    };
  }
  if (failedAttempts === 4) {
    return {
      type: 'explain',
      prompt: 'In two sentences, say what was missing from your proof.',
      seconds: 0,
      detail: '',
    };
  }
  if (failedAttempts === 5) {
    const detail = MICRO_TASKS[Math.abs(seed) % MICRO_TASKS.length];
    return {
      type: 'micro',
      prompt: 'Do it for real, then confirm. The slider unlocks after a pause.',
      seconds: 15,
      detail,
    };
  }
  const minutes = Math.max(2, Math.min(15, (failedAttempts - 5) * 2));
  const dueAt = new Date(now.getTime() + minutes * 60_000);
  return {
    type: 'cooldown',
    prompt: 'Cooldown. Think about what real proof looks like.',
    seconds: minutes * 60,
    dueAt: dueAt.toISOString(),
    detail: '',
  };
}

function failedCount(task) {
  return task.attempts.filter((a) => a.verdict !== 'pass' && a.verdict !== 'inconclusive').length;
}

module.exports = { generateChallenge, failedCount, PLEDGE };
