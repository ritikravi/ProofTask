# ProofTask Quick Start Guide

Get ProofTask running in under 5 minutes.

## Prerequisites

- Flutter SDK 3.13.5+ ([Install](https://flutter.dev/docs/get-started/install))
- Node.js 18+ ([Install](https://nodejs.org/))
- MongoDB 5.0+ ([Install](https://www.mongodb.com/try/download/community))
- Grok API key from [console.x.ai](https://console.x.ai)

## Option 1: Local Mode (Fastest)

**For quick testing and development.**

1. **Clone and setup Flutter app**
   ```bash
   git clone <repository-url>
   cd prooftask
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Configure on first launch**
   - Complete onboarding
   - Enter your Grok API key
   - Start creating tasks!

**That's it!** You're running in local mode with client-side verification.

⚠️ **Note**: Local mode keeps API keys in the app. Not for production.

## Option 2: Backend Mode (Production)

**For competition submission and production use.**

### Step 1: Start MongoDB

**macOS (Homebrew)**:
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community
```

**Docker**:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

**Verify MongoDB is running**:
```bash
mongosh --eval "db.version()"
```

### Step 2: Setup Backend

```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` with your values:
```env
XAI_API_KEY=xai-your-key-here
MONGODB_URI=mongodb://localhost:27017/prooftask
JWT_SECRET=your-random-secret-here
PORT=5000
CLIENT_ORIGIN=http://localhost:*
```

**Start backend**:
```bash
npm start
```

You should see:
```
✅ MongoDB connected
🚀 Server running on port 5000
```

### Step 3: Setup Flutter App

```bash
cd ..  # back to project root
flutter pub get
flutter run
```

### Step 4: Enable Backend Mode

1. Open the app
2. Tap Settings (gear icon)
3. Scroll to "Backend mode"
4. Toggle "Use backend API" ON
5. Enter backend URL: `http://localhost:5000`
6. Restart app

**Done!** Now all verification happens server-side.

## Quick Test

### Create Your First Task

1. Tap the **+** button
2. Title: "Test ProofTask"
3. Definition: "Submit any proof to test the system"
4. Tap "Add task"

### Submit Evidence

1. Open the task
2. Tap "Show me the receipts"
3. Choose **Text** evidence
4. Write: "This is a test submission with details about what I did"
5. Tap "Submit"
6. Watch the AI analyze your proof
7. See the verdict!

### Test a Failure

1. Create another task
2. Submit weak evidence: "did it"
3. Get roasted 😅
4. Complete the challenge
5. Submit better evidence
6. Pass and celebrate 🎉

## Troubleshooting

### Flutter Issues

**"SDK version >= X.X.X required"**
```bash
flutter upgrade
```

**"Package not found"**
```bash
flutter clean
flutter pub get
```

**Build errors**
```bash
flutter clean
cd ios && pod install && cd ..  # iOS only
flutter run
```

### Backend Issues

**MongoDB connection failed**
```bash
# Check if MongoDB is running
brew services list  # macOS
docker ps  # Docker

# Start MongoDB
brew services start mongodb-community  # macOS
docker start mongodb  # Docker
```

**Port 5000 already in use**
```bash
# Find process
lsof -ti:5000

# Kill it
kill -9 <PID>

# Or change port in .env
PORT=5001
```

**"Cannot find module"**
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

### Grok API Issues

**"Invalid API key"**
- Verify key at [console.x.ai](https://console.x.ai)
- Check for extra spaces in settings
- Ensure key starts with `xai-`

**"Rate limit exceeded"**
- Wait 1 minute
- Check your API quota at console.x.ai

**"Model not found"**
- Default model: `grok-2-vision-1212`
- Update in settings or backend .env

## What's Next?

1. **Explore Settings**
   - Adjust roast level (0-3)
   - Change strictness (0-3)
   - Try "Not today" mode for gentle feedback

2. **Test All Evidence Types**
   - Text: Simple explanations
   - Screenshot: Take photos of completed work
   - URL: Submit links to deployed sites
   - Commit: Paste GitHub commit URLs

3. **Experience Challenges**
   - Fail a task on purpose
   - Complete the typing challenge
   - See the escalation system

4. **Check Stats**
   - Tap the chart icon
   - View your streak
   - See completion rate

## Demo Tips

**For showcasing to others:**

1. **Start with a success**: Show evidence passing
2. **Then demonstrate failure**: Show the roast system
3. **Complete a challenge**: Show the accountability flow
4. **Adjust settings live**: Show customization
5. **Enable backend mode**: Explain production security

## Common Questions

**Q: Do I need both local AND backend mode?**  
A: No. Choose one:
- **Local**: Faster setup, development only
- **Backend**: Production-ready, secure

**Q: Can I switch between modes?**  
A: Yes! Toggle in settings anytime.

**Q: What if I don't have a Grok key?**  
A: Get one free at [console.x.ai](https://console.x.ai). Takes 2 minutes.

**Q: Do I need GitHub token?**  
A: Only for private repo commits. Public repos work without it.

**Q: Does it work offline?**  
A: Tasks sync locally. AI verification needs internet.

## Resources

- [Full README](README.md) - Complete documentation
- [Demo Guide](DEMO.md) - Demo script and user flows
- [Backend README](backend/README.md) - API reference
- [Competition Checklist](COMPETITION_CHECKLIST.md) - Submission guide

## Support

Having issues? Check:
1. This guide's troubleshooting section
2. README.md for detailed docs
3. GitHub issues (if available)

---

**Ready to prove your productivity? Let's go! 🚀**
