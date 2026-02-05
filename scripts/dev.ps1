# Start Backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm run dev" -Title "HomeFix Backend"

# Start Admin Panel
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd apps/admin_panel; npm run dev" -Title "HomeFix Admin Panel"
