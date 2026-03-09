# 🚀 Admin Panel Deployment Guide

## Quick Deploy Commands

### Option 1: Use the deployment script
```bash
# Run from project root
deploy_admin.bat
```

### Option 2: Manual deployment
```bash
# 1. Navigate to admin panel
cd apps/admin_panel

# 2. Install dependencies (if needed)
npm install

# 3. Build the app (creates 'out' folder)
npm run build

# 4. Go back to project root
cd ../..

# 5. Deploy to Firebase Hosting
firebase deploy --only hosting
```

## What the build does:
- Creates static files in `apps/admin_panel/out/` directory
- Firebase hosting serves files from this `out` folder
- Next.js exports optimized static assets

## Troubleshooting:
- If build fails, check for TypeScript errors
- If deployment fails, ensure Firebase CLI is logged in: `firebase login`
- If 'out' folder is missing, run `npm run build` in admin_panel directory

## Access deployed admin panel:
- URL will be shown after successful deployment
- Usually: `https://homefix-aa42d.web.app`