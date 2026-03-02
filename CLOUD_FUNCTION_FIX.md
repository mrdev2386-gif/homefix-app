# ✅ Cloud Function Export Fixed

## What Was Fixed

The `saveTechnicianStepData` function was defined in `functions/src/technician/onboarding.ts` but was NOT exported in `functions/src/index.ts`.

**Added this line to index.ts:**
```typescript
export const saveTechnicianStepData = techOnboarding.saveTechnicianStepData;
```

---

## Deployment Steps

### 1. Rebuild Functions
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
```

**Expected Output:**
```
> build
> tsc

[No errors]
```

### 2. Deploy Function
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only functions:saveTechnicianStepData
```

**Expected Output:**
```
=== Deploying to 'homefix-xxxxx'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: updating Node.js 18 function saveTechnicianStepData(us-central1)...
✔  functions[saveTechnicianStepData(us-central1)] Successful update operation.

✔  Deploy complete!
```

### 3. Verify Deployment

Check Firebase Console:
1. Go to https://console.firebase.google.com
2. Select your project
3. Navigate to Functions
4. Confirm `saveTechnicianStepData` appears in the list

---

## If Deployment Still Fails

### Option A: Deploy All Functions
```powershell
firebase deploy --only functions
```

This will deploy all functions and show you which ones are available.

### Option B: Check Build Output
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
```

Look for any TypeScript errors in the output.

### Option C: Check Compiled Output
```powershell
cd C:\Users\yash\projects\homefix\functions\lib
dir index.js
```

Open `lib/index.js` and search for `saveTechnicianStepData` to confirm it's exported.

---

## Next Steps After Successful Deployment

Once deployment succeeds, proceed with the investigation checklist:

1. **Clean Build:**
   ```powershell
   cd C:\Users\yash\projects\homefix\apps\technician_app
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Profile Update** - Follow INVESTIGATION_CHECKLIST.md Step 4

3. **Capture Console Logs** - Look for:
   ```
   [TECH WRITE] START uid=...
   [CF saveTechnicianStepData] authUid=...
   [CF saveTechnicianStepData] WRITE SUCCESS
   [TECH WRITE] SUCCESS via CF: ...
   ```

---

## Troubleshooting

### Error: "npm: command not found"
**Fix:** Install Node.js from https://nodejs.org/

### Error: "tsc: command not found"
**Fix:** 
```powershell
cd C:\Users\yash\projects\homefix\functions
npm install
```

### Error: "Firebase CLI not found"
**Fix:**
```powershell
npm install -g firebase-tools
firebase login
```

### Error: "Permission denied"
**Fix:** Ensure you're logged into the correct Firebase account:
```powershell
firebase login --reauth
firebase use --add
```

---

## Success Criteria

✅ Build completes without errors
✅ Deploy shows "Successful update operation"
✅ Function appears in Firebase Console
✅ Ready to test profile persistence
