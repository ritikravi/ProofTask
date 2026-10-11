# ProofTask

**Verification-Driven Productivity Agent**

ProofTask is a task management app that requires users to submit evidence—such as URLs, screenshots, text responses, or code commits—before marking a task complete. It uses AI-based content, vision, and web-verification workflows to assess evidence. When evidence is insufficient, the app delivers humorous passive-aggressive feedback and introduces lightweight accountability challenges.

## Features

### Core Functionality
- **Evidence-Based Completion**: No checkbox. Show receipts or face consequences.
- **Multi-Evidence Support**: Text, screenshots, URLs, and GitHub commits
- **AI Verification**: Powered by Grok API (xAI) with Anthropic Claude fallback
- **Vision Analysis**: Screenshots verified using Grok's vision capabilities
- **Challenge System**: Failed attempts trigger typing tests, quizzes, timers, micro-tasks, or cooldowns
- **Roast Bank**: Passive-aggressive feedback with adjustable intensity (gentle to HR-level)
- **Dispute System**: Challenge AI verdicts with additional context

### Extended Task Management
- **Priorities**: Low, medium, high priority levels
- **Deadlines**: Optional deadline tracking with overdue indicators
- **Acceptance Criteria**: Define what "done" means upfront
- **Required Evidence Types**: Specify which evidence types are acceptable
- **Task Status**: todo, in_progress, pending_verification, needs_revision, verified, blocked
- **Attempt History**: Full audit trail of all verification attempts

### Deployment Modes

#### Local Mode (Development)
- Client-side verification using AI APIs directly
- API keys stored securely on-device
- Fast iteration, no server required
- **Warning**: API keys are bundled in the app (not for production)

#### Backend Mode (Production)
- Server-proxied AI calls via Express.js backend
- API keys never leave the server
- MongoDB for multi-user task storage
- JWT authentication
- **Use this for competition submission**

## Tech Stack

### Frontend
- **Framework**: Flutter/Dart
- **State Management**: Riverpod
- **Routing**: go_router
- **Storage**: shared_preferences + flutter_secure_storage
- **HTTP**: dio (AI calls), http (backend API)

### Backend
- **Runtime**: Node.js + Express.js
- **Database**: MongoDB + Mongoose
- **AI**: Grok API (xAI)
- **Authentication**: JWT
- **Security**: Helmet, CORS, rate limiting

## Getting Started

### Prerequisites
- Flutter SDK 3.13.5+
- Node.js 18+ (for backend)
- MongoDB (for backend mode)
- Grok API key from [console.x.ai](https://console.x.ai)

### Flutter App Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Configure on first launch**
   - Enter your Grok API key (or Anthropic key as fallback)
   - Optionally add GitHub token for private repo verification
   - Adjust roast level and strictness to taste

### Backend Setup (Production Mode)

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your values:
   # XAI_API_KEY=xai-...
   # MONGODB_URI=mongodb://localhost:27017/prooftask
   # JWT_SECRET=your-secret-here
   # PORT=5000
   ```

4. **Start MongoDB**
   ```bash
   # macOS with Homebrew:
   brew services start mongodb-community

   # Or using Docker:
   docker run -d -p 27017:27017 --name mongodb mongo:latest
   ```

5. **Start the backend**
   ```bash
   npm start
   ```

6. **Configure Flutter app for backend mode**
   - Open Settings in the app
   - Enable "Use backend API"
   - Enter backend URL: `http://localhost:5000` (or your server URL)
   - Restart the app

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Login and get JWT

### Tasks
- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create task
- `GET /api/tasks/:id` - Get task details
- `PATCH /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `POST /api/tasks/:id/challenge/clear` - Clear challenge
- `POST /api/tasks/:id/subtasks` - Break down task

### Verification
- `POST /api/verify/:taskId/submit` - Submit evidence
- `POST /api/verify/:taskId/dispute` - Dispute verdict

## Project Structure

```
prooftask/
├── lib/
│   ├── app/                    # App shell and theme
│   ├── core/                   # Models, storage, LLM providers, API client
│   ├── features/
│   │   ├── challenges/         # Challenge generation
│   │   ├── onboarding/         # First-run setup
│   │   ├── settings/           # Settings screen
│   │   ├── stats/              # Statistics
│   │   ├── tasks/              # Task list, detail, submission screens
│   │   └── verification/       # Verification service
│   └── shared/                 # Widgets, effects, utilities
├── backend/
│   ├── src/
│   │   ├── middleware/         # Auth, error handling
│   │   ├── models/             # Mongoose schemas
│   │   ├── routes/             # Express routes
│   │   └── services/           # Grok, verification, challenge logic
│   ├── .env.example
│   └── package.json
└── README.md
```

## Competition Requirements

✅ **Evidence submission**: Text, screenshot, URL, commit  
✅ **AI verification**: Grok vision + content analysis  
✅ **Passive-aggressive feedback**: Roast bank with adjustable intensity  
✅ **Accountability challenges**: Typing, quiz, timer, micro-task, cooldown  
✅ **Backend mode**: API keys never in production client  
✅ **MongoDB persistence**: Multi-user task storage  
✅ **Authentication**: JWT-based user accounts  

## Architecture Highlights

### Security
- API keys stored in secure enclave (iOS Keychain / Android Keystore)
- Backend mode keeps secrets server-side only
- PBKDF2 password hashing with per-user salts
- SSRF protection on URL fetching
- Rate limiting on AI endpoints

### AI Integration
- Grok provider with structured outputs (function calling)
- Vision API for screenshot verification
- Fallback to offline roast bank when AI unavailable
- Dispute flow uses chain-of-thought reasoning

### UX Details
- No checkboxes—only proof matters
- Streak tracking for daily consistency
- Confetti + shake animations for victories (respects reduce-motion)
- Dark mode UI with lime accent

## Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# Web
flutter build web --release
```

### Environment Configuration

**Local mode (dev)**: Enter API keys in app settings  
**Backend mode (prod)**: Configure backend `.env`, enable in app settings

## Known Limitations

- AI verification is assistive, not forensic—determined users can still fake proof
- Screenshot analysis requires Grok vision model (grok-2-vision-1212)
- URL verification uses HEAD requests and basic HTML parsing
- GitHub commit verification requires public repos or PAT

## License

This project was created for the competition. See competition rules for usage terms.

## Acknowledgments

- Built with Flutter and Riverpod
- Powered by Grok API (xAI)
- Backend uses Express.js and MongoDB
- Inspired by the universal struggle to prove we did the thing
