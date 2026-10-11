# ProofTask Demo Guide

**Verification-Driven Productivity Agent**

## Overview

ProofTask is a task management app with a twist: **there's no checkbox**. To complete a task, you must submit evidence—a screenshot, URL, text explanation, or code commit. An AI judge (powered by Grok) verifies your proof. If you fail, you face accountability challenges.

## Key Features Demo

### 1. Task Creation with Extended Fields

**Create a task** with rich metadata:
- **Title**: "Deploy new landing page"
- **Definition**: "Ship the redesigned homepage to production"
- **Priority**: High
- **Deadline**: End of week
- **Acceptance Criteria**: "All tests pass, page loads under 2s, matches Figma"
- **Required Evidence**: Screenshot + URL

### 2. Evidence Submission

When ready to prove completion, choose evidence type:

#### Screenshot Evidence
1. Take screenshot of deployed page
2. App uploads to Grok vision API
3. AI analyzes: "Shows landing page with new design matching criteria"
4. **Verdict**: ✅ Pass

#### URL Evidence
1. Submit URL: `https://mysite.com`
2. App fetches page content
3. AI analyzes HTML structure
4. **Verdict**: ✅ Pass or ❌ Fail

#### Text Evidence
1. Write explanation: "Deployed via GitHub Actions, commit abc123"
2. AI assesses credibility
3. **Verdict**: 🤔 Weak (if vague) or ✅ Pass (if detailed)

#### GitHub Commit Evidence
1. Paste commit URL: `https://github.com/user/repo/commit/abc123`
2. App fetches commit via GitHub API
3. AI reviews diff and message
4. **Verdict**: ✅ Pass or ❌ Fail

### 3. Roast System

When verification fails, you get roasted:

**Roast Level 0 (Gentle)**:
> "Hmm. Not quite there yet. Give it another shot?"

**Roast Level 1 (Passive-Aggressive)** — Default:
> "I've seen more convincing evidence in a toddler's drawing. Try again."

**Roast Level 2 (Disappointed Parent)**:
> "I'm not mad. Just disappointed. We both know you can do better."

**Roast Level 3 (HR)**:
> "Per our previous conversation, this doesn't meet requirements. Please submit adequate documentation."

### 4. Challenge System

Failed attempts trigger escalating challenges:

**Attempt 1**: Typing test
- Type a sentence correctly within time limit
- Proves you're paying attention

**Attempt 2**: Quiz
- Answer a question about your task
- Forces you to think about what you're doing

**Attempt 3**: Timer lock
- 5-minute timeout before next attempt
- Cooling-off period

**Attempt 4**: Micro-task
- "Write down 3 things that went wrong"
- Reflection exercise

**Attempt 5+**: Cooldown
- Longer timeout (15+ minutes)
- Prevents spam attempts

### 5. Dispute System

Think the AI got it wrong?

1. Tap "Dispute verdict"
2. Add context: "The screenshot shows the staging environment, which matches production"
3. AI re-judges with your explanation
4. New verdict issued

### 6. Strictness Levels

Adjust how harsh the judge is:

**Lenient**: Gives benefit of doubt
**Normal**: Balanced verification (default)
**Strict**: Requires clear proof
**Ruthless**: Only perfect evidence passes

### 7. Streak Tracking

- Daily streak for verified tasks
- Stats on attempts vs successes
- "Roasted" count (failed attempts)

### 8. Backend Mode

**Local mode** (development):
- API keys in app
- Fast, no server needed
- ⚠️ Not production-safe

**Backend mode** (production):
- API keys on server only
- Multi-user with accounts
- Secure for competition submission

## Typical User Flow

### Morning: Create Tasks
```
☐ Write blog post about ProofTask
☐ Deploy API v2 to staging
☐ Review PRs from team
```

### Afternoon: Submit Proof
1. Finish blog post
2. Take screenshot of published article
3. Submit as evidence
4. AI: "Screenshot shows published post with today's date. Content visible."
5. ✅ Verified!

### Evening: Handle Failures
1. Try to complete "Deploy API"
2. Submit text: "I deployed it"
3. AI: "Weak. No URL, commit, or screenshot."
4. ❌ Fail + typing challenge
5. Complete challenge
6. Submit proper evidence: Staging URL + deployment log screenshot
7. ✅ Verified!

## Competition Alignment

### Problem Statement Requirements

✅ **Evidence submission** (text, screenshot, URL, commit)  
✅ **AI-based verification** (Grok vision + content analysis)  
✅ **Passive-aggressive feedback** (roast bank, adjustable)  
✅ **Accountability challenges** (typing, quiz, timer, micro-task, cooldown)  
✅ **Insufficient evidence handling** (roasts + challenges)  
✅ **Backend architecture** (keeps API keys server-side)

### Technical Highlights

- **Flutter frontend**: Cross-platform (iOS, Android, Web)
- **Grok API**: Latest vision + reasoning models
- **MongoDB**: Scalable task storage
- **Express backend**: RESTful API with JWT auth
- **Security**: PBKDF2, rate limiting, SSRF protection

## Demo Script

### Setup (2 minutes)
1. Launch app
2. Enter Grok API key (or enable backend mode)
3. Complete onboarding

### Create Task (1 minute)
1. Tap "+" to create task
2. Title: "Set up CI/CD pipeline"
3. Priority: High
4. Deadline: Tomorrow
5. Required evidence: Screenshot + URL

### Submit Evidence (2 minutes)
1. Open task
2. Tap "Show me the receipts"
3. Choose screenshot evidence
4. Take photo of GitHub Actions dashboard
5. Submit
6. Watch AI analyze
7. See verdict + roast/praise

### Demonstrate Failure (2 minutes)
1. Create task: "Learn Flutter"
2. Submit weak text: "I read some docs"
3. AI fails it with roast
4. Face typing challenge
5. Complete challenge
6. Submit better evidence: Screenshot of completed project
7. Pass and celebrate 🎉

### Show Settings (1 minute)
- Adjust roast level
- Change strictness
- Enable backend mode
- View streak stats

## Why ProofTask Works

**Traditional task apps**:
- Checkbox = instant gratification
- No accountability
- Easy to lie to yourself

**ProofTask**:
- Evidence = objective completion
- AI verification = impartial judge
- Challenges = thoughtful friction
- Humor = keeps it fun

## Demo Tips

1. **Show the roasts**: They're the app's personality
2. **Demonstrate vision API**: Screenshot verification is impressive
3. **Fail on purpose**: Shows the challenge system
4. **Adjust settings live**: Show customization
5. **Explain backend mode**: Security for production

## Questions to Address

**Q: Can users fake evidence?**  
A: Determined users can try, but it's friction + reflection, not forensics.

**Q: What if AI is wrong?**  
A: Dispute system lets users provide context for re-judgment.

**Q: Why Grok over other LLMs?**  
A: Vision API, function calling, and competitive pricing.

**Q: Backend vs local mode?**  
A: Local for dev speed, backend for production security.

**Q: How do challenges work?**  
A: Escalate with attempts—start gentle, get stricter.

## Conclusion

ProofTask turns task completion from a checkbox into a mini-game where you prove your progress. The AI judge keeps you honest, the roasts keep you entertained, and the challenges keep you engaged.

**No checkbox. Show receipts.**
