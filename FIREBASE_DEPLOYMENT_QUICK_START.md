# Firebase Functions Deployment Guide

## ✅ Pre-Deployment Checklist

- [x] firebase.json verified (Gen1 compliant)
- [x] All functions use Gen1 API
- [x] No CPU configuration in code
- [x] TypeScript builds successfully
- [x] No Gen2 imports in active code

---

## Step 1: Set Environment Variables

### In Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Functions** → **Runtime settings**
4. Add these environment variables:

```
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

5. Click **Save**

### Or via Firebase CLI:

```bash
firebase functions:config:set razorpay.key_id="your_key_id"
firebase functions:config:set razorpay.key_secret="your_key_secret"
```

---

## Step 2: Deploy Functions

### Option A: Deploy Only Functions

```bash
cd c:\Users\yash\projects\homefix
firebase deploy --only functions
```

### Option B: Deploy Everything (Functions + Firestore + Hosting)

```bash
cd c:\Users\yash\projects\homefix
firebase deploy
```

### Option C: Deploy Specific Function

```bash
firebase deploy --only functions:functionName
```

---

## Step 3: Monitor Deployment

### Watch deployment progress:

```bash
firebase deploy --only functions --debug
```

### View function logs:

```bash
firebase functions:log
```

### List all deployed functions:

```bash
firebase functions:list
```

---

## Step 4: Verify Deployment

### Check function status in Firebase Console:

1. Go to Firebase Console → Functions
2. Verify all functions show status: **OK** ✅
3. Check for any errors in the logs

### Test a callable function:

```bash
firebase functions:shell
> assignTechnicianToBooking({bookingId: 'test-booking-id'})
```

---

## Troubleshooting

### Error: "Cannot set CPU on functions because they are GCF gen 1"

**Solution**: This error should NOT occur. If it does:

1. Verify firebase.json has NO cpu configuration:
   ```json
   {
     "functions": {
       "source": "functions"
     }
   }
   ```

2. Clear Firebase cache:
   ```bash
   rm -rf .firebase
   firebase logout
   firebase login
   ```

3. Redeploy:
   ```bash
   firebase deploy --only functions --force
   ```

### Error: "Deployment failed"

1. Check logs:
   ```bash
   firebase deploy --only functions --debug
   ```

2. Verify TypeScript builds:
   ```bash
   cd functions
   npm run build
   ```

3. Check Node version:
   ```bash
   node --version  # Should be 22+
   ```

### Error: "Function not found"

1. Verify function is exported in `src/index.ts`
2. Rebuild:
   ```bash
   cd functions
   npm run build
   ```
3. Redeploy:
   ```bash
   firebase deploy --only functions
   ```

---

## Rollback

### If deployment causes issues:

```bash
# Redeploy previous version
firebase deploy --only functions --force

# Or delete specific function
firebase functions:delete functionName
firebase deploy --only functions
```

---

## Performance Optimization

### Monitor function performance:

1. Go to Firebase Console → Functions
2. Click on a function to see:
   - Execution count
   - Average duration
   - Error rate
   - Memory usage

### Optimize slow functions:

- Check Firestore query efficiency
- Reduce external API calls
- Use batch operations
- Cache frequently accessed data

---

## Security Verification

### Verify Firestore Rules:

```bash
firebase deploy --only firestore:rules
```

### Check function permissions:

1. Firebase Console → Functions
2. Click on function → Permissions
3. Verify only authorized users can call

---

## Monitoring & Alerts

### Set up error alerts:

1. Firebase Console → Functions
2. Click on function
3. Set up Cloud Logging alerts
4. Configure email notifications

### View real-time logs:

```bash
firebase functions:log --limit 50
```

---

## Deployment Complete! 🎉

Your Firebase Functions are now deployed and ready for production.

**Next Steps**:
1. Test functions in your apps
2. Monitor performance in Firebase Console
3. Set up alerts for errors
4. Plan regular updates

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `firebase deploy --only functions` | Deploy functions |
| `firebase functions:list` | List all functions |
| `firebase functions:log` | View function logs |
| `firebase functions:shell` | Test functions locally |
| `firebase deploy --only functions --force` | Force redeploy |
| `firebase functions:delete functionName` | Delete a function |

---

## Support

For issues or questions:
- Check Firebase Console logs
- Review this deployment guide
- Contact Firebase Support

---

**Status**: ✅ Ready for Deployment
**Last Updated**: 2024
