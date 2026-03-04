# Node.js 20 Runtime Upgrade

## Updated package.json

```json
"engines": {
  "node": "20"
}
```

## Deploy Steps

```powershell
cd C:\Users\yash\projects\homefix\functions
Remove-Item -Recurse -Force node_modules
npm install
cd ..
firebase deploy --only functions
```

## Verification

After deployment, confirm:
- Functions console shows Node.js 20 runtime
- All callable functions operational
- No breaking changes in business logic
