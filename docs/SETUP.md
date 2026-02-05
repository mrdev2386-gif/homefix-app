# Setup Instructions

## Prerequisites
- Node.js (v16+)
- Flutter
- PostgreSQL (or another database supported by Prisma)

## Backend
1. cd backend
2. npm install
3. Create .env file with DATABASE_URL
4. npx prisma generate
5. npx prisma migrate dev
6. npm run dev

## Admin Panel
1. cd apps/admin_panel
2. npm install
3. npm run dev

## Customer App
1. cd apps/customer_app
2. flutter pub get
3. flutter run

## Technician App
1. cd apps/technician_app
2. flutter pub get
3. flutter run
