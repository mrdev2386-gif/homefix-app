#!/bin/bash

echo "🛡️  Deploying Enhanced Firestore Security Rules..."

# Backup current rules
echo "💾 Backing up current rules..."
firebase firestore:rules:get > firestore_rules_backup_$(date +%Y%m%d_%H%M%S).rules

# Deploy new rules with approval enforcement
echo "🔧 Deploying enhanced security rules..."
firebase deploy --only firestore:rules

echo "✅ Firestore Rules deployment complete!"
echo ""
echo "📋 Enhanced Security Features:"
echo "  - Technician approval validation"
echo "  - Service creation blocking"
echo "  - Profile completion enforcement"
echo "  - Admin-only approval updates"
echo ""
echo "🔍 Verify rules:"
echo "firebase firestore:rules:get"