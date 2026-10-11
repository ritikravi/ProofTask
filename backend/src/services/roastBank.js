'use strict';

const ROASTS = {
  too_short: [
    "Ah, a bold few words. Riveting. Care to add a plot?",
    "That's not proof, that's a text-message-sized shrug.",
    "I've seen longer receipts for a single gum packet.",
  ],
  copy_title: [
    "You pasted the task title back at me. Proof of copy-paste, at least.",
    "'Do the thing: done.' Groundbreaking circular reasoning.",
  ],
  duplicate: [
    "I've seen this exact submission before. It wasn't proof then either.",
    "Same words, same result. Einstein had a name for that.",
  ],
  repetition: [
    "Repeating the same words louder is not additional evidence.",
    "Word count: impressive. Unique words: shy.",
  ],
  off_topic: [
    "Lovely writing. Sadly about something else entirely.",
    "This reads like proof of a different task. Wrong receipt.",
  ],
  stale_commit: [
    "Time travel is not a productivity strategy. That work predates the task.",
    "This commit is older than the task. Bold of you to claim it.",
  ],
  too_small: [
    "That image is mostly vibes and very few pixels.",
    "I've seen blanker, but not recently.",
  ],
  bad_link: [
    "That's not a link I can use. Nice try, though.",
    "I asked for a real address, not a feeling.",
  ],
  injection: [
    "Addressing the judge directly is bold. It is also not evidence.",
    "Nice try. The evaluator has read that trick before.",
  ],
  generic: [
    "I'd call this a promising first draft of proof.",
    "Vibes detected. Facts, not so much.",
    "This is the participation trophy of evidence.",
  ],
};

const PRAISE = [
  "Receipts accepted. I'm almost suspicious.",
  "Well. Look who brought actual evidence.",
  "Proof received. Reluctantly impressed.",
];

const GENTLE = [
  "Not quite there yet, and that's okay. A bit more detail and it's done.",
  "Close. Add the specifics and you're through.",
  "Today's a hard day, so let's keep it small: one concrete detail more.",
];

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function roastOffline(flags, notToday = false) {
  if (notToday) return pick(GENTLE);
  for (const f of flags) {
    if (ROASTS[f]) return pick(ROASTS[f]);
  }
  return pick(ROASTS.generic);
}

function praiseOffline() {
  return pick(PRAISE);
}

module.exports = { roastOffline, praiseOffline };
