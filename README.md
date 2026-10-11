# ProofTask 🎯

**Don't just say you did it. Show the receipts.**

ProofTask is an AI-powered task management app that holds you accountable by requiring real proof of completion. No more empty checkboxes – submit evidence and let AI verify your work.

<div align="center">
  
![Flutter](https://img.shields.io/badge/Flutter-3.10.0-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js)
![MongoDB](https://img.shields.io/badge/MongoDB-Latest-47A248?logo=mongodb)
![Grok AI](https://img.shields.io/badge/Grok_AI-Powered-7C3AED)
![License](https://img.shields.io/badge/License-MIT-blue)

</div>

---

## 📱 Screenshots

| Onboarding | Task List | Task Detail | Submit Proof |
|------------|-----------|-------------|--------------|
| ![Onboarding](docs/screenshots/1-onboarding.png) | ![Task List](docs/screenshots/2-task-list.png) | ![Task Detail](docs/screenshots/3-task-detail.png) | ![Submit Proof](docs/screenshots/4-submit-proof.png) |

| Verification Success | Verification Failed | Challenge | Settings |
|---------------------|---------------------|-----------|----------|
| ![Success](docs/screenshots/5-success.png) | ![Failed](docs/screenshots/6-failed.png) | ![Challenge](docs/screenshots/7-challenge.png) | ![Settings](docs/screenshots/8-settings.png) |

---

## ✨ Features

### 🎯 Core Features
- **Smart Task Management**: Create tasks with clear acceptance criteria and deadlines
- **AI Verification**: Powered by Grok AI & Anthropic Claude for intelligent proof validation
- **Evidence Submission**: Support for 4 types of evidence:
  - 📝 Text descriptions
  - 📸 Screenshots
  - 🔗 URLs
  - 💻 GitHub commits
- **Challenge System**: Face fun challenges when proof is weak to stay accountable
- **Priority Levels**: High, Medium, Low with visual indicators
- **Status Tracking**: Todo, In Progress, Pending Verification, Done, Blocked

### 📊 Analytics & Insights
- **Streak Tracking**: Monitor your daily completion streak
- **Success Rate**: Track your proof acceptance rate
- **Last 7 Days Chart**: Visual representation of your productivity
- **Most Roasted Tasks**: See which tasks gave you the most trouble

### 🎨 UI/UX Highlights
- **Beautiful Purple/Violet Theme**: Modern, clean design
- **Smooth Animations**: Confetti on success, shake on failure
- **Roast Intensity Levels**: From "Gentle Nudge" to "Drill Sergeant"
- **Bottom Navigation**: Easy access to Tasks, Stats, Challenges, Settings
- **Filter System**: Quickly filter tasks by status (All, Todo, In Progress, Done)

---

## 🛠️ Tech Stack

### Frontend (Flutter)
```yaml
Flutter SDK: 3.10.0
Dart: 3.0.0

Core Dependencies:
- flutter_riverpod: ^2.0.0     # State management
- go_router: ^6.0.0            # Navigation
- shared_preferences: ^2.0.15  # Local storage
- http: ^0.13.5                # API calls
- google_fonts: ^4.0.3         # Typography

AI Integration:
- anthropic_sdk_dart: ^0.1.3   # Claude API

Media & Files:
- image_picker: ^0.8.6+1       # Camera/Gallery
- share_plus: ^6.3.0           # Share receipts
- path_provider: ^2.0.12       # File paths

Utilities:
- intl: ^0.17.0                # Internationalization
- crypto: ^3.0.2               # Hashing
```

### Backend (Node.js)
```json
{
  "runtime": "Node.js 18+",
  "framework": "Express.js 4.18+",
  "database": "MongoDB",
  
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.0.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.7.0",
    "dotenv": "^16.0.3",
    "axios": "^1.4.0"
  }
}
```

### AI Providers
- **Primary**: Grok AI (xAI) - Fast, cost-effective
- **Fallback**: Anthropic Claude 3.5 Sonnet - High accuracy

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Node.js 18+ and npm
- MongoDB (local or Atlas)
- Grok API key (get from [console.x.ai](https://console.x.ai))
- (Optional) Anthropic API key for fallback

### 📱 Flutter App Setup

1. **Clone the repository**
```bash
git clone https://github.com/ritikravi/ProofTask.git
cd ProofTask
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For development
flutter run

# For Android release
flutter build apk --release

# For iOS release
flutter build ios --release
```

4. **Configure API Keys** (in-app)
   - Open the app → Settings
   - Enter your Grok API key (xai-...)
   - (Optional) Enter Anthropic API key for fallback

### 🖥️ Backend Setup

1. **Navigate to backend directory**
```bash
cd backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure environment variables**
```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/prooftask
JWT_SECRET=your_super_secret_jwt_key_here

# AI API Keys
GROK_API_KEY=xai-your-grok-key
ANTHROPIC_API_KEY=sk-ant-your-key

# GitHub (optional)
GITHUB_TOKEN=ghp_your_token
```

4. **Start the server**
```bash
# Development
npm run dev

# Production
npm start
```

5. **Test the API**
```bash
# Health check
curl http://localhost:5000/health

# See backend/API_TESTING.md for detailed API documentation
```

---

## 📖 Usage Guide

### Creating Your First Task

1. **Launch the app** and complete onboarding
2. **Tap the + button** on the home screen
3. **Fill in task details**:
   - Title: "Write launch post"
   - Description: "Published with a link"
   - Priority: High
   - Deadline: Select a date

4. **Set acceptance criteria** (optional):
   - At least 300 words
   - Includes product screenshots
   - Shares the live URL as proof

5. **Tap "Create Task"**

### Submitting Proof

1. **Open a task** from your task list
2. **Tap "Show me the receipts"**
3. **Choose evidence type**:
   - **Text**: Describe what you did in detail
   - **Screenshot**: Upload an image from camera/gallery
   - **URL**: Paste a link to your work
   - **Commit**: GitHub commit or PR URL

4. **Submit for verification**
5. **Wait for AI verdict**

### Understanding Verdicts

- ✅ **Pass**: Proof accepted! Task marked complete
- ⚠️ **Weak**: Technically counts, but could be better
- ❌ **Fail**: Not enough proof → Face a challenge

### Challenge Types

When proof fails, you'll face one of these:
- 📝 **Typing Pledge**: Type an accountability statement
- ⏱️ **Focus Hold**: Stay in the app for X minutes
- ❄️ **Cooldown**: Wait before you can retry
- 🧠 **Quiz**: Answer questions about your task
- 💡 **Explain**: Write a detailed explanation
- 🎯 **Micro Task**: Complete a small related task

---

## 🏗️ Architecture

### App Structure
```
lib/
├── app/                    # App setup & theme
├── core/                   # Models, storage, API client
├── features/
│   ├── onboarding/         # Welcome screen
│   ├── tasks/              # Task management
│   ├── challenges/         # Challenge system
│   ├── stats/              # Analytics
│   ├── settings/           # Configuration
│   └── verification/       # AI verification
└── shared/                 # Reusable widgets

backend/
├── src/
│   ├── models/             # MongoDB schemas
│   ├── routes/             # API endpoints
│   ├── services/           # Business logic
│   └── middleware/         # Auth, error handling
```

### Backend API Endpoints

#### Authentication
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Sign in
- `GET /api/auth/me` - Get current user

#### Tasks
- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create task
- `GET /api/tasks/:id` - Get task details
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task

#### Verification
- `POST /api/verify/submit` - Submit evidence
- `POST /api/verify/dispute` - Appeal verdict
- `POST /api/verify/challenge` - Generate challenge

See [backend/API_TESTING.md](backend/API_TESTING.md) for detailed API documentation.

---

## 🎨 Customization

### Theme Colors
Edit `lib/app/theme.dart`:
```dart
abstract class AppColors {
  static const canvas = Color(0xFFA98BF5);      // Background
  static const surface = Color(0xFF4A2FA8);     // Cards
  static const lime = Color(0xFFD4F54A);        // Primary action
  static const coral = Color(0xFFFF4D6D);       // Error/High priority
  static const amber = Color(0xFFFFD166);       // Warning/Medium
  static const ink = Color(0xFF1E1147);         // Text
}
```

### Roast Levels
Edit roast intensity in Settings:
1. **Gentle Nudge** - Supportive and kind
2. **Friendly Jab** - Light-hearted
3. **Honest Critique** - Direct but fair
4. **Drill Sergeant** - Maximum accountability

### Strictness Levels
- **Lenient**: AI is more forgiving
- **Normal**: Balanced verification
- **Strict**: Higher proof standards
- **Ruthless**: Extremely demanding

---

## 🔐 Security Features

- **SSRF Protection**: URL validation to prevent malicious requests
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **JWT Authentication**: Secure token-based auth
- **Helmet.js**: HTTP security headers
- **CORS**: Configurable cross-origin requests
- **Input Validation**: Sanitization on all endpoints

---

## 🧪 Testing

### Run Flutter tests
```bash
flutter test
```

### Test backend
```bash
cd backend
npm test
```

### Manual testing
See [backend/API_TESTING.md](backend/API_TESTING.md) for:
- cURL examples
- Postman collection
- API response schemas

---

## 📦 Build & Deploy

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS App
```bash
flutter build ios --release
# Then archive in Xcode
```

### Backend Deployment

#### Using Docker
```bash
cd backend
docker build -t prooftask-backend .
docker run -p 5000:5000 --env-file .env prooftask-backend
```

#### Using PM2
```bash
npm install -g pm2
pm2 start src/index.js --name prooftask
pm2 save
```

#### Environment Variables (Production)
```env
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/prooftask
JWT_SECRET=super_secure_secret_change_this
GROK_API_KEY=xai-...
ANTHROPIC_API_KEY=sk-ant-...
CORS_ORIGIN=https://your-app-domain.com
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **AI Providers**: xAI (Grok), Anthropic (Claude)
- **UI Inspiration**: Modern task management apps
- **Font**: Plus Jakarta Sans by Google Fonts
- **Icons**: Material Icons & Cupertino Icons

---

## 📧 Contact

**Ritik Raushan**  
GitHub: [@ritikravi](https://github.com/ritikravi)  
Project Link: [https://github.com/ritikravi/ProofTask](https://github.com/ritikravi/ProofTask)

---

## 🎯 Roadmap

### Coming Soon
- [ ] Social features (share tasks with friends)
- [ ] Team workspaces
- [ ] Custom challenge creation
- [ ] Advanced analytics dashboard
- [ ] Calendar integration
- [ ] Habit tracking
- [ ] Voice evidence submission
- [ ] Web app version
- [ ] Browser extension

### Future Ideas
- AI-generated task suggestions
- Integration with productivity tools (Notion, Todoist, etc.)
- Gamification with achievements and leaderboards
- Export reports (PDF, CSV)
- Multi-language support

---

<div align="center">

**Built with ❤️ by developers who actually want to get things done**

⭐ Star this repo if ProofTask helps you stay accountable!

</div>
