#!/bin/bash

echo "🚀 Deploying Technician Approval Cloud Functions..."

# Navigate to functions directory
cd functions

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Deploy specific functions for approval workflow
echo "🔧 Deploying approval validation functions..."
firebase deploy --only functions:validateTechnicianApproval,functions:createTechnicianService,functions:onTechnicianProfileUpdate

# Deploy existing service functions with updated validation
echo "🔧 Deploying updated service functions..."
firebase deploy --only functions:addTechnicianService,functions:updateTechnicianServiceNew

echo "✅ Cloud Functions deployment complete!"
echo ""
echo "📋 Deployed Functions:"
echo "  - validateTechnicianApproval (NEW)"
echo "  - createTechnicianService (NEW)" 
echo "  - onTechnicianProfileUpdate (NEW)"
echo "  - addTechnicianService (UPDATED)"
echo "  - updateTechnicianServiceNew (UPDATED)"
echo ""
echo "🔍 Verify deployment:"
echo "firebase functions:list"