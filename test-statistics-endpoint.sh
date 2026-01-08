#!/bin/bash

API_URL="https://waba.easydoochat.com"
CAMPAIGN_ID="26a10b42-0fe5-4db9-b435-1733e00276b9"

echo "=== Testing Campaign Statistics Endpoint ==="
echo ""

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

echo "2. Testing campaign statistics endpoint..."
echo "URL: ${API_URL}/campaign-statistics/campaigns/${CAMPAIGN_ID}/statistics"
echo ""

STATS=$(curl -s -X GET "${API_URL}/campaign-statistics/campaigns/${CAMPAIGN_ID}/statistics" \
  -H "Authorization: Bearer $TOKEN")

echo "$STATS" | jq '.'

if echo "$STATS" | jq -e '.success' > /dev/null 2>&1; then
  echo ""
  echo "✅ Statistics endpoint working!"
  echo ""
  echo "Summary:"
  echo "$STATS" | jq '.data | {campaign_id, total_recipients, sent_count, failed_count, delivery_rate, failure_rate}'
else
  echo ""
  echo "❌ Statistics endpoint failed"
fi

echo ""
echo "=== Test Complete ==="

