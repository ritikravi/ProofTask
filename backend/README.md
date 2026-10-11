# ProofTask Backend

Node.js + Express + MongoDB + Grok API backend for ProofTask.

## Quick Start

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your keys
npm run dev
```

## Environment Variables

- `XAI_API_KEY` — Your xAI Grok API key (get from console.x.ai)
- `XAI_MODEL` — Model name (default: grok-2-vision-1212)
- `MONGODB_URI` — MongoDB connection string
- `JWT_SECRET` — Secret for JWT signing (generate with `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`)
- `PORT` — Server port (default: 5000)
- `CLIENT_ORIGIN` — Flutter app origin for CORS (e.g. http://localhost:8080)
- `GITHUB_TOKEN` — Optional GitHub PAT for private repos

## API Endpoints

### Auth
- `POST /api/auth/register` — Register user
- `POST /api/auth/login` — Login

### Tasks
- `GET /api/tasks` — List tasks
- `POST /api/tasks` — Create task
- `GET /api/tasks/:id` — Get task
- `PATCH /api/tasks/:id` — Update task
- `DELETE /api/tasks/:id` — Delete task
- `POST /api/tasks/:id/challenge/clear` — Clear challenge
- `POST /api/tasks/:id/subtasks` — Split task into subtasks

### Verification
- `POST /api/verify/:taskId/submit` — Submit evidence
- `POST /api/verify/:taskId/dispute` — Dispute verdict

## Database Schema

### Task
- `userId` — Owner (null for anonymous)
- `title`, `definition` — Task description
- `deadline`, `priority`, `acceptanceCriteria`, `requiredEvidenceTypes`, `expectedOutcome`, `verificationPolicy` — Extended fields
- `status` — todo | in_progress | pending_verification | needs_revision | verified | blocked | done
- `challenge` — Current challenge (if locked)
- `attempts[]` — Evidence submission history

### User
- `username`, `passwordHash` — Auth
- `roastLevel`, `strictness`, `notToday` — Preferences

## Security

- Helmet + CORS + rate limiting
- SSRF-guarded URL fetching
- Injection pattern detection
- Grok API key never exposed to clients
- Optional JWT auth (softAuth allows anonymous use)

## Production Checklist

- [ ] Set strong `JWT_SECRET`
- [ ] Restrict `CLIENT_ORIGIN` to your domain
- [ ] Use MongoDB Atlas or secured instance
- [ ] Enable HTTPS
- [ ] Tighten rate limits if needed
- [ ] Review CORS allowed origins
