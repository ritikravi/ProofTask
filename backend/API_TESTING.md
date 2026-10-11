# ProofTask API Testing Guide

Complete API testing examples using curl. Base URL: `http://localhost:5000`

## Authentication Endpoints

### Register User
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123",
    "displayName": "Test User"
  }'
```

**Expected Response** (201):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "userId": "507f1f77bcf86cd799439011"
}
```

### Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123"
  }'
```

**Expected Response** (200):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "userId": "507f1f77bcf86cd799439011"
}
```

**Save the token** for authenticated requests:
```bash
export TOKEN="<token-from-response>"
```

## Task Endpoints

### List All Tasks
```bash
# Anonymous (returns tasks with userId: null)
curl http://localhost:5000/api/tasks

# Authenticated (returns user's tasks)
curl http://localhost:5000/api/tasks \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200):
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "title": "Deploy new feature",
    "definition": "Ship v2.0 to production",
    "status": "todo",
    "priority": "high",
    "deadline": "2024-12-31T23:59:59Z",
    "acceptanceCriteria": "All tests pass, deployed to prod",
    "requiredEvidenceTypes": ["screenshot", "url"],
    "attempts": [],
    "challenge": null,
    "createdAt": "2024-01-15T10:00:00Z"
  }
]
```

### Create Task (Minimal)
```bash
curl -X POST http://localhost:5000/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Write blog post",
    "definition": "Complete article about ProofTask"
  }'
```

### Create Task (Full)
```bash
curl -X POST http://localhost:5000/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Deploy API v2",
    "definition": "Ship new API to production",
    "deadline": "2024-12-31T23:59:59.000Z",
    "priority": "high",
    "acceptanceCriteria": "All tests pass, no downtime, monitoring shows healthy",
    "requiredEvidenceTypes": ["screenshot", "url", "commit"],
    "expectedOutcome": "API v2 live in production with zero downtime",
    "verificationPolicy": "strict"
  }'
```

**Expected Response** (201):
```json
{
  "id": "507f1f77bcf86cd799439012",
  "title": "Deploy API v2",
  "status": "todo",
  ...
}
```

**Save task ID**:
```bash
export TASK_ID="<task-id-from-response>"
```

### Get Single Task
```bash
curl http://localhost:5000/api/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Update Task
```bash
curl -X PATCH http://localhost:5000/api/tasks/$TASK_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "in_progress",
    "priority": "medium"
  }'
```

**Allowed fields**: title, definition, deadline, priority, acceptanceCriteria, requiredEvidenceTypes, expectedOutcome, verificationPolicy, status

### Delete Task
```bash
curl -X DELETE http://localhost:5000/api/tasks/$TASK_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response** (200):
```json
{
  "deleted": true
}
```

### Clear Challenge
```bash
curl -X POST http://localhost:5000/api/tasks/$TASK_ID/challenge/clear \
  -H "Authorization: Bearer $TOKEN"
```

### Create Subtasks
```bash
curl -X POST http://localhost:5000/api/tasks/$TASK_ID/subtasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "titles": [
      "Write API documentation",
      "Set up CI/CD pipeline",
      "Deploy to staging"
    ]
  }'
```

**Expected Response** (201):
```json
{
  "parent": { ... },
  "subtasks": [
    { "id": "...", "title": "Write API documentation", ... },
    { "id": "...", "title": "Set up CI/CD pipeline", ... },
    { "id": "...", "title": "Deploy to staging", ... }
  ]
}
```

## Verification Endpoints

### Submit Text Evidence
```bash
curl -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "evidenceType": "text",
    "evidenceValue": "Deployed successfully via GitHub Actions. Build #42 passed all tests. Production URL: https://api.example.com shows v2.0 in health check.",
    "strictness": 1,
    "roastLevel": 1,
    "notToday": false
  }'
```

**Expected Response** (200):
```json
{
  "outcome": {
    "verdict": "pass",
    "confidence": 0.92,
    "reasoning": "Evidence includes deployment method, build number, test results, and production URL verification",
    "message": "Fine. That counts.",
    "hash": "sha256:abc123...",
    "missing": [],
    "flags": [],
    "usedAi": true
  },
  "task": {
    "id": "507f1f77bcf86cd799439012",
    "status": "verified",
    "completedAt": "2024-01-15T15:30:00Z",
    "attempts": [
      {
        "evidenceType": "text",
        "evidenceValue": "Deployed successfully...",
        "verdict": "pass",
        "confidence": 0.92,
        ...
      }
    ]
  }
}
```

### Submit Screenshot Evidence
```bash
# First, encode image to base64
IMAGE_BASE64=$(base64 -i screenshot.png)

curl -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"evidenceType\": \"screenshot\",
    \"evidenceValue\": \"Deployment dashboard showing success\",
    \"evidenceBase64\": \"$IMAGE_BASE64\",
    \"evidenceMime\": \"image/png\",
    \"strictness\": 1,
    \"roastLevel\": 1
  }"
```

### Submit URL Evidence
```bash
curl -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "evidenceType": "url",
    "evidenceValue": "https://api.example.com/health",
    "strictness": 1,
    "roastLevel": 1
  }'
```

### Submit Commit Evidence
```bash
curl -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "evidenceType": "commit",
    "evidenceValue": "https://github.com/username/repo/commit/abc123def456",
    "strictness": 1,
    "roastLevel": 1
  }'
```

### Dispute Verdict
```bash
curl -X POST http://localhost:5000/api/verify/$TASK_ID/dispute \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "originalText": "The original evidence that was rejected",
    "note": "This screenshot shows the staging environment which mirrors production exactly. The deployment succeeded as shown by the green checkmarks and timestamp matching the task deadline.",
    "strictness": 1,
    "roastLevel": 1
  }'
```

**Expected Response** (200):
```json
{
  "outcome": {
    "verdict": "pass",
    "confidence": 0.88,
    "reasoning": "Disputed. Upon review with additional context about staging environment, evidence is sufficient.",
    "message": "Alright, fine. I'll allow it.",
    ...
  },
  "task": { ... }
}
```

## Error Responses

### 400 Bad Request
```json
{
  "errors": [
    {
      "msg": "Invalid value",
      "param": "title",
      "location": "body"
    }
  ]
}
```

### 401 Unauthorized
```json
{
  "error": "Invalid token"
}
```

### 404 Not Found
```json
{
  "error": "Task not found"
}
```

### 409 Conflict
```json
{
  "error": "Task already verified"
}
```
or
```json
{
  "error": "Task locked — clear challenge first"
}
```

### 429 Rate Limit
```json
{
  "error": "AI rate limit. Wait a moment."
}
```

### 500 Server Error
```json
{
  "error": "Internal server error"
}
```

## Testing Workflow

### Complete Flow Example

```bash
#!/bin/bash

# 1. Register user
echo "1. Registering user..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@example.com",
    "password": "DemoPass123",
    "displayName": "Demo User"
  }')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')
echo "Token: $TOKEN"

# 2. Create task
echo -e "\n2. Creating task..."
TASK_RESPONSE=$(curl -s -X POST http://localhost:5000/api/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test ProofTask API",
    "definition": "Verify all endpoints work correctly",
    "priority": "high"
  }')

TASK_ID=$(echo $TASK_RESPONSE | jq -r '.id')
echo "Task ID: $TASK_ID"

# 3. List tasks
echo -e "\n3. Listing tasks..."
curl -s http://localhost:5000/api/tasks \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 4. Submit evidence (will likely fail with weak evidence)
echo -e "\n4. Submitting weak evidence..."
curl -s -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "evidenceType": "text",
    "evidenceValue": "did it",
    "strictness": 1,
    "roastLevel": 2
  }' | jq '.'

# 5. Clear challenge
echo -e "\n5. Clearing challenge..."
curl -s -X POST http://localhost:5000/api/tasks/$TASK_ID/challenge/clear \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 6. Submit better evidence
echo -e "\n6. Submitting detailed evidence..."
curl -s -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "evidenceType": "text",
    "evidenceValue": "Successfully tested all API endpoints using curl. Registration, login, task CRUD, and verification all working correctly. Evidence includes this detailed explanation and the fact that I am making this API call.",
    "strictness": 1,
    "roastLevel": 1
  }' | jq '.'

echo -e "\n✅ Workflow complete!"
```

## Rate Limiting Test

```bash
# This should trigger rate limit (30 requests per minute on AI endpoints)
for i in {1..35}; do
  echo "Request $i"
  curl -X POST http://localhost:5000/api/verify/$TASK_ID/submit \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "evidenceType": "text",
      "evidenceValue": "test"
    }' | jq -r '.error // .outcome.verdict'
  sleep 1
done
```

## Health Check

```bash
curl http://localhost:5000/health
```

**Expected Response** (200):
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:00:00.000Z"
}
```

## Tips

1. **Save tokens**: Export as environment variable for easy reuse
2. **Use jq**: Pretty-print JSON responses (`| jq '.'`)
3. **Check logs**: Backend logs show detailed request/response info
4. **Test failures**: Intentionally submit weak evidence to see roasts
5. **Monitor MongoDB**: Use MongoDB Compass or `mongosh` to inspect data

## Postman Collection

Import this into Postman for easier testing:

```json
{
  "info": {
    "name": "ProofTask API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:5000"
    },
    {
      "key": "token",
      "value": ""
    },
    {
      "key": "taskId",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"SecurePass123\",\n  \"displayName\": \"Test User\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/register"
            }
          }
        },
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"SecurePass123\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{baseUrl}}/api/auth/login"
            }
          }
        }
      ]
    }
  ]
}
```

---

**Happy Testing! 🚀**
