# Environment Variables Setup Guide
## Cloud Functions v2 Configuration

This guide provides instructions for setting up environment variables required by Cloud Functions after the `functions.config()` migration.

---

## Required Environment Variables

### Razorpay Configuration
```bash
RAZORPAY_KEY_ID          # Razorpay API Key ID (rzp_live_xxx or rzp_test_xxx)
RAZORPAY_KEY_SECRET      # Razorpay API Secret Key
RAZORPAY_WEBHOOK_SECRET  # Razorpay Webhook Secret for signature verification
```

---

## Setup Methods

### Method 1: Firebase CLI (Recommended for Production)

```bash
# Set all Razorpay variables at once
firebase functions:config:set \
  razorpay.key_id="rzp_live_xxxxxxxxxxxxx" \
  razorpay.key_secret="xxxxxxxxxxxxxxxxxxxxx" \
  razorpay.webhook_secret="xxxxxxxxxxxxxxxxxxxxx"

# Verify configuration
firebase functions:config:get

# Deploy functions with new config
firebase deploy --only functions
```

### Method 2: .env File (Local Development)

Create `functions/.env`:
```env
# Razorpay Configuration (Test Mode)
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=xxxxxxxxxxxxxxxxxxxxx
```

**Note:** The `.env` file is automatically loaded by Firebase Functions Emulator.

### Method 3: Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to: **Cloud Functions** → Select function → **Edit**
4. Scroll to **Runtime, build, connections and security settings**
5. Click **Runtime environment variables**
6. Add variables:
   - `RAZORPAY_KEY_ID`
   - `RAZORPAY_KEY_SECRET`
   - `RAZORPAY_WEBHOOK_SECRET`
7. Click **Deploy**

---

## Verification

### Check Current Configuration
```bash
# View all config
firebase functions:config:get

# View specific config
firebase functions:config:get razorpay
```

### Test Locally
```bash
# Start emulator with .env file
cd functions
firebase emulators:start --only functions

# Test bank verification endpoint
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/verifyTechnicianBankAccount \
  -H "Content-Type: application/json" \
  -d '{"accountNumber":"123456789","ifscCode":"SBIN0001234",...}'
```

---

## Security Best Practices

### ✅ DO
- Use different keys for development and production
- Store production keys in Firebase Config (encrypted)
- Use test mode keys (`rzp_test_xxx`) for development
- Rotate keys periodically
- Use webhook secrets for signature verification

### ❌ DON'T
- Commit `.env` files to Git (add to `.gitignore`)
- Share API keys in chat/email
- Use production keys in development
- Hardcode keys in source code
- Expose keys in client-side code

---

## Troubleshooting

### Issue: "Razorpay configuration not found"
**Solution:**
```bash
# Check if variables are set
firebase functions:config:get razorpay

# If empty, set them:
firebase functions:config:set razorpay.key_id="YOUR_KEY"
```

### Issue: "Invalid API key"
**Solution:**
- Verify key format: `rzp_live_xxx` or `rzp_test_xxx`
- Check for extra spaces or quotes
- Ensure key is active in Razorpay Dashboard

### Issue: "Webhook signature verification failed"
**Solution:**
- Verify `RAZORPAY_WEBHOOK_SECRET` matches Razorpay Dashboard
- Check webhook URL is correct
- Ensure secret has no extra spaces

---

## Migration from functions.config()

If you previously used `firebase functions:config:set`, the values are still stored but need to be accessed differently:

### Old Way (Deprecated)
```typescript
const key = functions.config().razorpay.key_id;
```

### New Way (v2 Compatible)
```typescript
const key = process.env.RAZORPAY_KEY_ID || '';
```

**Note:** Firebase automatically converts `razorpay.key_id` to `RAZORPAY_KEY_ID` environment variable.

---

## Environment Variable Naming Convention

Firebase automatically converts config paths to environment variables:

| Firebase Config | Environment Variable |
|----------------|---------------------|
| `razorpay.key_id` | `RAZORPAY_KEY_ID` |
| `razorpay.key_secret` | `RAZORPAY_KEY_SECRET` |
| `razorpay.webhook_secret` | `RAZORPAY_WEBHOOK_SECRET` |

**Pattern:** `config.path.name` → `CONFIG_PATH_NAME` (uppercase, dots to underscores)

---

## Quick Commands Reference

```bash
# View all config
firebase functions:config:get

# Set a variable
firebase functions:config:set key.name="value"

# Unset a variable
firebase functions:config:unset key.name

# Clone config from another project
firebase functions:config:clone --from=source-project

# Export config to .env format
firebase functions:config:get > .runtimeconfig.json
```

---

## Production Deployment Checklist

- [ ] Set production Razorpay keys (live mode)
- [ ] Verify webhook secret matches Razorpay Dashboard
- [ ] Test in staging environment first
- [ ] Monitor logs after deployment
- [ ] Verify bank verification works
- [ ] Test payment webhooks
- [ ] Check error rates in Cloud Functions dashboard

---

## Support

For issues related to:
- **Firebase Configuration:** [Firebase Support](https://firebase.google.com/support)
- **Razorpay API:** [Razorpay Support](https://razorpay.com/support)
- **Cloud Functions:** [Google Cloud Support](https://cloud.google.com/support)

---

**Last Updated:** 2025-01-XX  
**Version:** 2.0 (Cloud Functions v2)
