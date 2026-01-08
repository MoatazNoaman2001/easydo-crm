# 🚀 EasyDo Webhook Integration Guide

## 📋 **Quick Start**

1. **Get your trigger details** from the EasyDo dashboard
2. **Generate webhook signatures** for security
3. **Send POST requests** to your webhook URL

## 🔐 **Security - Webhook Signatures**

All webhook requests require an `X-Webhook-Signature` header.

### JavaScript/Node.js Example:
```javascript
const crypto = require('crypto');

function generateSignature(payload, secret) {
  return crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
}

// Usage
const payload = {
  event: 'user.created',
  data: { user_id: '123', name: 'John', phone: '+1234567890' }
};
const secret = 'whsec_your_webhook_secret_here';
const signature = generateSignature(payload, secret);

// Header: X-Webhook-Signature: sha256=abc123...
```

### Python Example:
```python
import hmac, hashlib, json

def generate_signature(payload, secret):
    return hmac.new(
        secret.encode(), json.dumps(payload).encode(), hashlib.sha256
    ).hexdigest()

payload = {'event': 'user.created', 'data': {'user_id': '123', 'phone': '+1234567890'}}
signature = generate_signature(payload, 'whsec_your_secret')
```

### cURL Example:
```bash
# Replace with your actual values
TRIGGER_ID="5a14d043-2046-448b-ac6a-7d9f83c82176"
SECRET="whsec_8c24575379dc17d9372ed6b506471bf6e955246c29ea675fc0e12605e7a"

PAYLOAD='{"event":"user.created","data":{"user_id":"123","name":"John","phone":"+201098518194"}}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -hex | cut -d' ' -f2 | sed 's/^/sha256=/')

curl -X POST "https://easydo.whatsapp.com/api/webhooks/trigger/$TRIGGER_ID" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

## 🎯 **Your Active Triggers**

### Event-Based Customer Trigger
- **ID**: `5a14d043-2046-448b-ac6a-7d9f83c82176`
- **Type**: Event-driven (user.created)
- **Template**: notification_preferences_confirmation
- **Phone Path**: `data.phone`

### CRUD Customer Triggers
- **ID**: `7f87e53e-4477-4c24-9752-8f0b92a7a64d` (upsert)
- **ID**: `443106ad-3121-4c2f-84ad-af176968d627` (upsert)

### Template Trigger
- **ID**: `1314a707-ad5f-4bfd-8759-0e312d813bdd` (upsert)

## 📝 **Example Payloads**

### User Created Event:
```json
{
  "event": "user.created",
  "timestamp": "2025-01-03T21:40:00Z",
  "data": {
    "user_id": "12345",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "created_at": "2025-01-03T21:40:00Z"
  }
}
```

### Bulk Users:
```json
{
  "event": "user.created",
  "data": {
    "users": [
      {"user_id": "123", "name": "John", "phone": "+1234567890"},
      {"user_id": "124", "name": "Jane", "phone": "+0987654321"}
    ]
  }
}
```
**URL**: `https://easydo.whatsapp.com/api/webhooks/trigger/YOUR_TRIGGER_ID?phone_path=data.users[*].phone`

### CRUD Customer:
```json
{
  "customer_id": "CUST-001",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "subscription_status": "active"
}
```

## ✅ **Response Examples**

**Success:**
```json
{
  "success": true,
  "message": "Webhook processed successfully",
  "event_name": "user.created",
  "phones_sent": 1
}
```

**Error:**
```json
{
  "success": false,
  "message": "Webhook processing failed",
  "error": "Invalid signature"
}
```

## 🧪 **Testing**

Use the `/test` endpoint to validate without sending real messages:
```
POST https://easydo.whatsapp.com/api/webhooks/triggers/YOUR_TRIGGER_ID/test
```

## 📊 **Monitoring**

Check logs to monitor delivery:
```
GET https://easydo.whatsapp.com/api/webhooks/triggers/YOUR_TRIGGER_ID/logs?limit=10
```

---

**Need help?** Contact EasyDo support or check the webhook settings in your dashboard for trigger IDs and secrets.
