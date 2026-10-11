# ProofTask Deployment Guide

Complete deployment instructions for various environments.

## Prerequisites

- Flutter SDK 3.13.5+
- Node.js 18+
- MongoDB instance (local or cloud)
- Grok API key from console.x.ai
- Domain name (for production)
- SSL certificate (for production)

## Backend Deployment

### Option 1: Traditional VPS (DigitalOcean, AWS EC2, etc.)

#### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Install PM2 for process management
sudo npm install -g pm2
```

#### 2. Deploy Application

```bash
# Clone repository
git clone <your-repo-url>
cd prooftask/backend

# Install dependencies
npm ci --only=production

# Create .env file
nano .env
```

**Production .env**:
```env
XAI_API_KEY=xai-your-production-key
XAI_MODEL=grok-2-vision-1212
MONGODB_URI=mongodb://localhost:27017/prooftask
JWT_SECRET=<generate-with-openssl-rand-hex-64>
PORT=5000
CLIENT_ORIGIN=https://yourdomain.com
NODE_ENV=production
```

#### 3. Start with PM2

```bash
# Start application
pm2 start src/index.js --name prooftask

# Save PM2 config
pm2 save

# Setup PM2 to restart on boot
pm2 startup
```

#### 4. Setup Nginx Reverse Proxy

```bash
sudo apt install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/prooftask
```

**Nginx configuration**:
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/prooftask /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### 5. Setup SSL with Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

### Option 2: Docker Deployment

#### 1. Create Dockerfile

**backend/Dockerfile**:
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/index.js"]
```

#### 2. Create docker-compose.yml

**backend/docker-compose.yml**:
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:6.0
    container_name: prooftask-mongo
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
    volumes:
      - mongodb_data:/data/db
    ports:
      - "27017:27017"

  backend:
    build: .
    container_name: prooftask-api
    restart: unless-stopped
    environment:
      XAI_API_KEY: ${XAI_API_KEY}
      XAI_MODEL: grok-2-vision-1212
      MONGODB_URI: mongodb://admin:${MONGO_PASSWORD}@mongodb:27017/prooftask?authSource=admin
      JWT_SECRET: ${JWT_SECRET}
      PORT: 5000
      CLIENT_ORIGIN: ${CLIENT_ORIGIN}
      NODE_ENV: production
    ports:
      - "5000:5000"
    depends_on:
      - mongodb
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:5000/health')"]
      interval: 30s
      timeout: 3s
      retries: 3

volumes:
  mongodb_data:
```

#### 3. Deploy with Docker Compose

```bash
# Create .env for docker-compose
cat > .env.docker << EOF
XAI_API_KEY=xai-your-key
JWT_SECRET=$(openssl rand -hex 64)
MONGO_PASSWORD=$(openssl rand -hex 16)
CLIENT_ORIGIN=https://yourdomain.com
EOF

# Build and start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Option 3: Heroku

```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login
heroku login

# Create app
heroku create prooftask-api

# Add MongoDB addon
heroku addons:create mongolab:sandbox

# Set environment variables
heroku config:set XAI_API_KEY=xai-your-key
heroku config:set JWT_SECRET=$(openssl rand -hex 64)
heroku config:set CLIENT_ORIGIN=https://yourdomain.com

# Deploy
git subtree push --prefix backend heroku main

# View logs
heroku logs --tail
```

### Option 4: MongoDB Atlas (Cloud Database)

1. **Create cluster** at [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. **Get connection string**: `mongodb+srv://username:password@cluster.mongodb.net/prooftask`
3. **Update .env**: Use Atlas URI instead of local MongoDB
4. **Whitelist IP**: Add your server's IP in Atlas Network Access

## Flutter App Deployment

### iOS Deployment

#### 1. Setup

```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Update Bundle Identifier
# In Xcode: Runner > General > Bundle Identifier

# Setup signing
# Xcode > Signing & Capabilities > Team
```

#### 2. Build

```bash
# Build release
flutter build ios --release

# Or build archive for App Store
flutter build ipa
```

#### 3. Deploy to App Store

1. Open Xcode
2. Product > Archive
3. Distribute App > App Store Connect
4. Upload to TestFlight
5. Submit for review

### Android Deployment

#### 1. Create Keystore

```bash
keytool -genkey -v -keystore ~/prooftask-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias prooftask
```

#### 2. Configure Signing

**android/key.properties**:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=prooftask
storeFile=/Users/yourname/prooftask-release-key.jks
```

**android/app/build.gradle**:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 3. Build

```bash
# Build APK
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

#### 4. Deploy to Play Store

1. Go to [play.google.com/console](https://play.google.com/console)
2. Create app
3. Upload app bundle
4. Fill in store listing
5. Submit for review

### Web Deployment

#### 1. Build

```bash
flutter build web --release
```

#### 2. Deploy to Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

#### 3. Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize
firebase init hosting
# Choose build/web as public directory

# Deploy
firebase deploy --only hosting
```

#### 4. Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel --prod
```

## Environment Configuration

### Production Checklist

#### Backend
- [ ] Strong JWT_SECRET (64+ characters)
- [ ] Restrict CLIENT_ORIGIN to actual domain
- [ ] Use production MongoDB (Atlas or secured instance)
- [ ] Enable MongoDB authentication
- [ ] Set NODE_ENV=production
- [ ] Configure proper logging
- [ ] Setup monitoring (e.g., PM2, New Relic)
- [ ] Enable HTTPS only
- [ ] Configure firewall rules
- [ ] Setup automated backups

#### Flutter App
- [ ] Update backend URL to production
- [ ] Remove debug logging
- [ ] Test on real devices
- [ ] Verify SSL certificate validation
- [ ] Check app permissions
- [ ] Test offline behavior
- [ ] Verify API key security
- [ ] Run performance profiling
- [ ] Test on various screen sizes

## Monitoring & Maintenance

### Backend Monitoring

```bash
# PM2 monitoring
pm2 monit

# View logs
pm2 logs prooftask

# Restart on issues
pm2 restart prooftask

# Check MongoDB status
sudo systemctl status mongod
```

### Application Monitoring

#### Setup PM2 Plus (free tier)

```bash
pm2 plus
# Follow prompts to connect
```

#### Custom Health Checks

```bash
# Add to crontab
*/5 * * * * curl -f http://localhost:5000/health || systemctl restart prooftask
```

### Database Backups

#### Automated MongoDB Backups

```bash
# Create backup script
cat > /usr/local/bin/backup-mongodb.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mongodb"
mkdir -p $BACKUP_DIR

mongodump --out $BACKUP_DIR/$DATE

# Keep only last 7 days
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} \;
EOF

chmod +x /usr/local/bin/backup-mongodb.sh

# Add to crontab (daily at 2 AM)
0 2 * * * /usr/local/bin/backup-mongodb.sh
```

## Scaling

### Horizontal Scaling (Multiple Backend Instances)

#### Using PM2 Cluster Mode

```bash
pm2 start src/index.js -i max --name prooftask-cluster
```

#### Using Load Balancer (Nginx)

```nginx
upstream prooftask_backend {
    least_conn;
    server localhost:5001;
    server localhost:5002;
    server localhost:5003;
    server localhost:5004;
}

server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://prooftask_backend;
        # ... other proxy settings
    }
}
```

### Database Scaling

- Use MongoDB Atlas auto-scaling
- Enable replica sets for high availability
- Add read replicas for read-heavy workloads
- Implement caching (Redis) for frequent queries

## Troubleshooting

### Common Issues

**Backend won't start**
```bash
# Check logs
pm2 logs prooftask --lines 100

# Check if port is in use
sudo lsof -i :5000

# Check MongoDB
sudo systemctl status mongod
```

**MongoDB connection failed**
```bash
# Restart MongoDB
sudo systemctl restart mongod

# Check MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log

# Test connection
mongosh --eval "db.version()"
```

**SSL certificate issues**
```bash
# Renew Let's Encrypt
sudo certbot renew

# Test SSL
curl https://api.yourdomain.com/health
```

## Security Best Practices

1. **Never commit secrets** to Git
2. **Use environment variables** for all config
3. **Enable firewall** and allow only necessary ports
4. **Keep dependencies updated** regularly
5. **Use HTTPS everywhere** in production
6. **Implement rate limiting** on all endpoints
7. **Monitor for suspicious activity**
8. **Regular security audits**
9. **Backup database** regularly
10. **Use strong passwords** for everything

## Rollback Procedure

```bash
# If deployment fails, rollback

# Backend
pm2 stop prooftask
git checkout <previous-working-commit>
npm ci
pm2 restart prooftask

# Flutter web
# Redeploy previous build
netlify rollback
```

---

**Need help?** Check logs first, then refer to documentation or open an issue.
