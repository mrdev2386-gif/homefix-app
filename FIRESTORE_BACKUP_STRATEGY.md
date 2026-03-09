# 🔒 FIRESTORE BACKUP STRATEGY
## HomeFix Platform - Data Protection & Recovery

**Last Updated**: 2026-01-XX  
**Status**: ✅ PRODUCTION READY

---

## 📋 OVERVIEW

This document outlines the automated backup strategy for HomeFix Firestore database to ensure data protection, disaster recovery, and compliance.

---

## 🎯 BACKUP OBJECTIVES

- **RPO (Recovery Point Objective)**: 24 hours
- **RTO (Recovery Time Objective)**: 4 hours
- **Retention Period**: 30 days (daily), 12 months (monthly)
- **Storage Location**: Google Cloud Storage

---

## 🔄 AUTOMATED BACKUP SCHEDULE

### Daily Backups
```bash
# Runs every day at 2:00 AM UTC
gcloud firestore export gs://homefix-backups/daily/$(date +%Y-%m-%d) \
  --project=homefix-production
```

### Weekly Backups
```bash
# Runs every Sunday at 3:00 AM UTC
gcloud firestore export gs://homefix-backups/weekly/$(date +%Y-W%U) \
  --project=homefix-production
```

### Monthly Backups
```bash
# Runs on 1st of every month at 4:00 AM UTC
gcloud firestore export gs://homefix-backups/monthly/$(date +%Y-%m) \
  --project=homefix-production
```

---

## 🛠️ SETUP INSTRUCTIONS

### 1. Create Cloud Storage Bucket

```bash
# Create backup bucket with lifecycle policy
gsutil mb -p homefix-production -c STANDARD -l us-central1 gs://homefix-backups

# Set lifecycle policy (auto-delete after 30 days for daily backups)
cat > lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 30,
          "matchesPrefix": ["daily/"]
        }
      },
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 365,
          "matchesPrefix": ["monthly/"]
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://homefix-backups
```

### 2. Grant Firestore Export Permissions

```bash
# Grant Firestore service account permission to write to bucket
gcloud projects add-iam-policy-binding homefix-production \
  --member="serviceAccount:service-PROJECT_NUMBER@gcp-sa-firestore.iam.gserviceaccount.com" \
  --role="roles/datastore.importExportAdmin"

gsutil iam ch \
  serviceAccount:service-PROJECT_NUMBER@gcp-sa-firestore.iam.gserviceaccount.com:objectAdmin \
  gs://homefix-backups
```

### 3. Setup Cloud Scheduler Jobs

#### Daily Backup Job
```bash
gcloud scheduler jobs create http firestore-daily-backup \
  --schedule="0 2 * * *" \
  --uri="https://firestore.googleapis.com/v1/projects/homefix-production/databases/(default):exportDocuments" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{
    "outputUriPrefix": "gs://homefix-backups/daily/'$(date +%Y-%m-%d)'",
    "collectionIds": []
  }' \
  --oauth-service-account-email="firestore-backup@homefix-production.iam.gserviceaccount.com" \
  --time-zone="UTC"
```

#### Weekly Backup Job
```bash
gcloud scheduler jobs create http firestore-weekly-backup \
  --schedule="0 3 * * 0" \
  --uri="https://firestore.googleapis.com/v1/projects/homefix-production/databases/(default):exportDocuments" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{
    "outputUriPrefix": "gs://homefix-backups/weekly/'$(date +%Y-W%U)'",
    "collectionIds": []
  }' \
  --oauth-service-account-email="firestore-backup@homefix-production.iam.gserviceaccount.com" \
  --time-zone="UTC"
```

#### Monthly Backup Job
```bash
gcloud scheduler jobs create http firestore-monthly-backup \
  --schedule="0 4 1 * *" \
  --uri="https://firestore.googleapis.com/v1/projects/homefix-production/databases/(default):exportDocuments" \
  --http-method=POST \
  --headers="Content-Type=application/json" \
  --message-body='{
    "outputUriPrefix": "gs://homefix-backups/monthly/'$(date +%Y-%m)'",
    "collectionIds": []
  }' \
  --oauth-service-account-email="firestore-backup@homefix-production.iam.gserviceaccount.com" \
  --time-zone="UTC"
```

---

## 🔍 MONITORING & VERIFICATION

### Check Backup Status

```bash
# List recent backups
gsutil ls -lh gs://homefix-backups/daily/

# Verify backup size
gsutil du -sh gs://homefix-backups/daily/$(date +%Y-%m-%d)

# Check Cloud Scheduler job status
gcloud scheduler jobs describe firestore-daily-backup
```

### Setup Alerts

```bash
# Create alert for failed backups
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Firestore Backup Failure" \
  --condition-display-name="Backup Job Failed" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=300s \
  --condition-filter='resource.type="cloud_scheduler_job" AND metric.type="logging.googleapis.com/user/backup_failure"'
```

---

## 🔄 RESTORE PROCEDURES

### Full Database Restore

```bash
# Restore from specific backup
gcloud firestore import gs://homefix-backups/daily/2026-01-15 \
  --project=homefix-production

# Restore to different project (for testing)
gcloud firestore import gs://homefix-backups/daily/2026-01-15 \
  --project=homefix-staging
```

### Selective Collection Restore

```bash
# Restore only specific collections
gcloud firestore import gs://homefix-backups/daily/2026-01-15 \
  --collection-ids=bookings,customers,technicians \
  --project=homefix-production
```

### Point-in-Time Recovery

```bash
# List available backups
gsutil ls gs://homefix-backups/daily/

# Restore from specific date
gcloud firestore import gs://homefix-backups/daily/2026-01-10 \
  --project=homefix-production
```

---

## 🧪 TESTING BACKUP INTEGRITY

### Monthly Restore Test

```bash
# Test restore to staging environment
gcloud firestore import gs://homefix-backups/monthly/$(date +%Y-%m) \
  --project=homefix-staging

# Verify data integrity
# Run validation queries to ensure data is complete
```

### Automated Validation Script

```bash
#!/bin/bash
# validate_backup.sh

BACKUP_DATE=$(date +%Y-%m-%d)
BACKUP_PATH="gs://homefix-backups/daily/$BACKUP_DATE"

# Check if backup exists
if gsutil ls $BACKUP_PATH > /dev/null 2>&1; then
  echo "✅ Backup exists: $BACKUP_PATH"
  
  # Check backup size
  SIZE=$(gsutil du -s $BACKUP_PATH | awk '{print $1}')
  if [ $SIZE -gt 1000000 ]; then
    echo "✅ Backup size OK: $SIZE bytes"
  else
    echo "❌ Backup size too small: $SIZE bytes"
    exit 1
  fi
else
  echo "❌ Backup not found: $BACKUP_PATH"
  exit 1
fi
```

---

## 📊 BACKUP METRICS

### Expected Backup Sizes
- **Daily Backup**: ~500 MB - 2 GB
- **Weekly Backup**: ~500 MB - 2 GB
- **Monthly Backup**: ~500 MB - 2 GB

### Storage Costs (Estimated)
- **Daily Backups (30 days)**: ~$15-60/month
- **Monthly Backups (12 months)**: ~$6-24/month
- **Total Estimated Cost**: ~$21-84/month

---

## 🚨 DISASTER RECOVERY PLAN

### Scenario 1: Accidental Data Deletion

1. Identify affected collections and time of deletion
2. Locate most recent backup before deletion
3. Restore affected collections to staging
4. Verify data integrity
5. Restore to production during maintenance window

**Estimated Recovery Time**: 2-4 hours

### Scenario 2: Database Corruption

1. Assess extent of corruption
2. Identify last known good backup
3. Restore full database to staging
4. Run integrity checks
5. Switch production to restored database

**Estimated Recovery Time**: 4-6 hours

### Scenario 3: Regional Outage

1. Verify backup availability in Cloud Storage
2. Create new Firestore instance in different region
3. Restore from most recent backup
4. Update application configuration
5. Redirect traffic to new region

**Estimated Recovery Time**: 6-8 hours

---

## 📝 COMPLIANCE & AUDIT

### Backup Audit Log

```bash
# View backup operation logs
gcloud logging read "resource.type=cloud_scheduler_job AND resource.labels.job_id=firestore-daily-backup" \
  --limit=50 \
  --format=json
```

### Compliance Requirements

- ✅ **GDPR**: 30-day retention for user data recovery
- ✅ **SOC 2**: Automated backup with monitoring
- ✅ **ISO 27001**: Documented backup and restore procedures
- ✅ **PCI DSS**: Encrypted backups in secure storage

---

## 🔐 SECURITY CONSIDERATIONS

### Backup Encryption
- ✅ All backups encrypted at rest (Google-managed keys)
- ✅ Access restricted via IAM policies
- ✅ Audit logging enabled for all access

### Access Control
```bash
# Grant read-only access to backup bucket
gsutil iam ch user:admin@homefix.com:objectViewer gs://homefix-backups

# Grant restore permissions
gcloud projects add-iam-policy-binding homefix-production \
  --member="user:admin@homefix.com" \
  --role="roles/datastore.importExportAdmin"
```

---

## 📞 SUPPORT & ESCALATION

**Backup Issues**: Contact DevOps team  
**Emergency Restore**: Call 9508322397  
**Google Cloud Support**: Enterprise Support Plan

---

## ✅ CHECKLIST

### Initial Setup
- [ ] Create Cloud Storage bucket
- [ ] Configure lifecycle policies
- [ ] Grant Firestore export permissions
- [ ] Create Cloud Scheduler jobs
- [ ] Setup monitoring alerts
- [ ] Test restore procedure
- [ ] Document recovery procedures

### Monthly Tasks
- [ ] Verify backup completion
- [ ] Check backup sizes
- [ ] Test restore to staging
- [ ] Review storage costs
- [ ] Update documentation

### Quarterly Tasks
- [ ] Full disaster recovery drill
- [ ] Review and update procedures
- [ ] Audit access logs
- [ ] Optimize storage costs

---

## 📚 ADDITIONAL RESOURCES

- [Firestore Export/Import Documentation](https://cloud.google.com/firestore/docs/manage-data/export-import)
- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs)
- [Cloud Storage Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle)

---

**Document Version**: 1.0  
**Last Review**: 2026-01-XX  
**Next Review**: 2026-04-XX
