#!/bin/bash

API_URL="https://waba.easydoochat.com"

echo "=== Testing Campaign Queue System ==="
echo ""

# Get token
echo "1. Getting auth token..."
TOKEN=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "sanjay.patel@easydotasks.com",
    "password": "Sanjay@123456"
  }' | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Failed to get auth token"
  exit 1
fi
echo "✅ Got auth token"
echo ""

# Test queue stats endpoint first
echo "2. Testing queue stats endpoint..."
QUEUE_STATS=$(curl -s -X GET "${API_URL}/campaigns/queue/stats" \
  -H "Authorization: Bearer $TOKEN")

echo "$QUEUE_STATS" | jq '.'

if echo "$QUEUE_STATS" | jq -e '.success' > /dev/null 2>&1; then
  echo "✅ Queue stats endpoint working"
else
  echo "❌ Queue stats endpoint failed"
  echo "Response: $QUEUE_STATS"
fi
echo ""

# Test scheduler stats
echo "3. Testing scheduler stats endpoint..."
SCHEDULER_STATS=$(curl -s -X GET "${API_URL}/campaigns/scheduler/stats" \
  -H "Authorization: Bearer $TOKEN")

echo "$SCHEDULER_STATS" | jq '.'
echo ""

# Create campaign with future time
echo "4. Creating test campaign..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  SCHEDULED_TIME=$(date -u -v+5M +"%Y-%m-%dT%H:%M:%S.000Z")
else
  SCHEDULED_TIME=$(date -u -d "+5 minutes" +"%Y-%m-%dT%H:%M:%S.000Z")
fi

CAMPAIGN_RESPONSE=$(curl -s -X POST "${API_URL}/campaigns" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Queue Test Campaign",
    "description": "Testing Redis queue system",
    "groupId": "8778e8f7-90b9-4d5f-8a74-a4a9e275075e",
    "templateName": "simple_template_v3",
    "templateCode": "en",
    "templateType": "UTILITY",
    "templateParams": {
      "header": [],
      "body": ["Test Message"],
      "button": []
    },
    "scheduledAt": "'"$SCHEDULED_TIME"'"
  }')

CAMPAIGN_ID=$(echo "$CAMPAIGN_RESPONSE" | jq -r '.campaign.id')

if [ "$CAMPAIGN_ID" = "null" ] || [ -z "$CAMPAIGN_ID" ]; then
  echo "❌ Failed to create campaign"
  echo "Response: $CAMPAIGN_RESPONSE"
  exit 1
fi
echo "✅ Campaign created: $CAMPAIGN_ID"
echo ""

# Execute campaign
echo "5. Executing campaign..."
EXECUTE_RESPONSE=$(curl -s -X POST "${API_URL}/campaigns/${CAMPAIGN_ID}/execute" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

echo "$EXECUTE_RESPONSE" | jq '.'

JOB_ID=$(echo "$EXECUTE_RESPONSE" | jq -r '.result.jobId')
if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
  echo "⚠️  No job ID returned (may be using old system)"
else
  echo "✅ Campaign queued with job ID: $JOB_ID"
fi
echo ""

# Monitor progress
echo "6. Monitoring campaign progress..."
for i in {1..15}; do
  PROGRESS=$(curl -s -X GET "${API_URL}/campaigns/${CAMPAIGN_ID}/progress" \
    -H "Authorization: Bearer $TOKEN")
  
  STATUS=$(echo "$PROGRESS" | jq -r '.progress.status // "unknown"')
  SENT=$(echo "$PROGRESS" | jq -r '.progress.sent // 0')
  FAILED=$(echo "$PROGRESS" | jq -r '.progress.failed // 0')
  TOTAL=$(echo "$PROGRESS" | jq -r '.progress.total // 0')
  PCT=$(echo "$PROGRESS" | jq -r '.progress.percentage // 0')
  
  echo "[$i] Status: $STATUS | Progress: $PCT% | Sent: $SENT | Failed: $FAILED | Total: $TOTAL"
  
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ]; then
    echo ""
    echo "✅ Campaign finished with status: $STATUS"
    break
  fi
  
  sleep 2
done
echo ""

# Final queue stats
echo "7. Final queue stats..."
curl -s -X GET "${API_URL}/campaigns/queue/stats" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""

# Final campaign state
echo "8. Final campaign state..."
curl -s -X GET "${API_URL}/campaigns/${CAMPAIGN_ID}" \
  -H "Authorization: Bearer $TOKEN" | jq '.campaign | {id, name, status, queue_status, total_recipients, sent_count, failed_count}'

echo ""
echo "=== Test Complete ==="