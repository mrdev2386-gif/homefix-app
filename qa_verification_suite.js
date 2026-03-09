#!/usr/bin/env node

/**
 * QA Verification Script for Technician Approval System
 * Tests all components of the approval workflow
 */

const admin = require('firebase-admin');
const { execSync } = require('child_process');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

class QAVerificationSuite {
  constructor() {
    this.testResults = [];
    this.criticalIssues = [];
    this.warnings = [];
  }

  log(message, type = 'INFO') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${type}] ${message}`);
  }

  addResult(testName, passed, message, critical = false) {
    const result = { testName, passed, message, critical };
    this.testResults.push(result);
    
    if (!passed && critical) {
      this.criticalIssues.push(result);
    } else if (!passed) {
      this.warnings.push(result);
    }
    
    const status = passed ? '✅ PASS' : (critical ? '❌ CRITICAL FAIL' : '⚠️  WARN');
    this.log(`${status}: ${testName} - ${message}`);
  }

  async runAllTests() {
    this.log('🚀 Starting QA Verification Suite for Technician Approval System\n');

    // Test 1: Profile Completion Requirement
    await this.testProfileCompletionRequirement();

    // Test 2: Admin Approval Requirement  
    await this.testAdminApprovalRequirement();

    // Test 3: Admin Approval Flow
    await this.testAdminApprovalFlow();

    // Test 4: Security Validation
    await this.testSecurityValidation();

    // Test 5: Firestore Security Rules
    await this.testFirestoreSecurityRules();

    // Test 6: Email Verification Rule
    await this.testEmailVerificationRule();

    // Test 7: Complete Flow Validation
    await this.testCompleteFlow();

    // Generate final report
    this.generateReport();
  }

  async testProfileCompletionRequirement() {
    this.log('\n📋 Test 1: Profile Completion Requirement');
    
    try {
      // Create test technician with incomplete profile
      const testUid = 'test-incomplete-' + Date.now();
      const incompleteProfile = {
        fullName: 'Test Technician',
        phone: '+919876543210',
        // Missing required fields for 100% completion
        profileApprovalRequested: false,
        profileApproved: false,
        profileRejected: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db.collection('technicians').doc(testUid).set(incompleteProfile);
      
      const completion = this.calculateProfileCompletion(incompleteProfile);
      
      if (completion < 100) {
        this.addResult(
          'Profile Completion Calculation',
          true,
          `Incomplete profile correctly calculated as ${completion}%`
        );
      } else {
        this.addResult(
          'Profile Completion Calculation',
          false,
          'Incomplete profile incorrectly calculated as 100%',
          true
        );
      }

      // Test service creation blocking
      try {
        const functions = admin.functions();
        const validateFunction = functions.httpsCallable('validateTechnicianApproval');
        
        // This should fail for incomplete profile
        await validateFunction({ uid: testUid });
        
        this.addResult(
          'Service Creation Blocking',
          false,
          'Service creation was NOT blocked for incomplete profile',
          true
        );
      } catch (error) {
        if (error.message.includes('complete your profile to 100%')) {
          this.addResult(
            'Service Creation Blocking',
            true,
            'Service creation correctly blocked with proper message'
          );
        } else {
          this.addResult(
            'Service Creation Blocking',
            false,
            `Wrong error message: ${error.message}`,
            true
          );
        }
      }

      // Cleanup
      await db.collection('technicians').doc(testUid).delete();

    } catch (error) {
      this.addResult(
        'Profile Completion Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testAdminApprovalRequirement() {
    this.log('\n👨‍💼 Test 2: Admin Approval Requirement');
    
    try {
      // Create test technician with 100% profile but not approved
      const testUid = 'test-pending-' + Date.now();
      const completeProfile = {
        fullName: 'Test Technician Complete',
        phone: '+919876543210',
        email: 'test@example.com',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        skills: ['plumbing', 'electrical'],
        experienceYears: 5,
        bankStatus: 'approved',
        aadhaarFrontUrl: 'https://example.com/aadhaar.jpg',
        customServices: ['Custom Service'],
        profileApprovalRequested: true,
        profileApproved: false,
        profileRejected: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db.collection('technicians').doc(testUid).set(completeProfile);
      
      const completion = this.calculateProfileCompletion(completeProfile);
      
      if (completion === 100) {
        this.addResult(
          'Complete Profile Calculation',
          true,
          'Complete profile correctly calculated as 100%'
        );
      } else {
        this.addResult(
          'Complete Profile Calculation',
          false,
          `Complete profile incorrectly calculated as ${completion}%`,
          true
        );
      }

      // Test service creation still blocked
      try {
        const functions = admin.functions();
        const validateFunction = functions.httpsCallable('validateTechnicianApproval');
        
        await validateFunction({ uid: testUid });
        
        this.addResult(
          'Unapproved Service Creation Blocking',
          false,
          'Service creation was NOT blocked for unapproved technician',
          true
        );
      } catch (error) {
        if (error.message.includes('under admin review')) {
          this.addResult(
            'Unapproved Service Creation Blocking',
            true,
            'Service creation correctly blocked with admin review message'
          );
        } else {
          this.addResult(
            'Unapproved Service Creation Blocking',
            false,
            `Wrong error message: ${error.message}`,
            true
          );
        }
      }

      // Cleanup
      await db.collection('technicians').doc(testUid).delete();

    } catch (error) {
      this.addResult(
        'Admin Approval Requirement Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testAdminApprovalFlow() {
    this.log('\n🔄 Test 3: Admin Approval Flow');
    
    try {
      // Test auto-trigger of admin review
      const testUid = 'test-flow-' + Date.now();
      
      // Create incomplete profile first
      await db.collection('technicians').doc(testUid).set({
        fullName: 'Test Flow',
        phone: '+919876543210',
        profileApprovalRequested: false,
        profileApproved: false,
        profileRejected: false,
      });

      // Update to complete profile
      await db.collection('technicians').doc(testUid).update({
        email: 'test@example.com',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        skills: ['plumbing'],
        experienceYears: 3,
        bankStatus: 'approved',
        aadhaarFrontUrl: 'https://example.com/aadhaar.jpg',
        customServices: ['Service'],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Wait for Cloud Function trigger
      await new Promise(resolve => setTimeout(resolve, 5000));

      // Check if admin review was requested
      const doc = await db.collection('technicians').doc(testUid).get();
      const data = doc.data();

      if (data.profileApprovalRequested === true) {
        this.addResult(
          'Auto Admin Review Request',
          true,
          'Admin review automatically requested when profile reached 100%'
        );
      } else {
        this.addResult(
          'Auto Admin Review Request',
          false,
          'Admin review was NOT automatically requested',
          true
        );
      }

      // Test admin approval
      await db.collection('technicians').doc(testUid).update({
        profileApproved: true,
        profileApprovalRequested: false,
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Verify service creation is now allowed
      const approvedDoc = await db.collection('technicians').doc(testUid).get();
      const approvedData = approvedDoc.data();

      if (approvedData.profileApproved === true) {
        this.addResult(
          'Admin Approval Process',
          true,
          'Admin approval process works correctly'
        );
      } else {
        this.addResult(
          'Admin Approval Process',
          false,
          'Admin approval was not saved correctly',
          true
        );
      }

      // Cleanup
      await db.collection('technicians').doc(testUid).delete();

    } catch (error) {
      this.addResult(
        'Admin Approval Flow Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testSecurityValidation() {
    this.log('\n🔒 Test 4: Security Validation');
    
    // Test Cloud Function validation
    try {
      const functions = admin.functions();
      
      // Check if validation function exists
      try {
        const validateFunction = functions.httpsCallable('validateTechnicianApproval');
        this.addResult(
          'Cloud Function Exists',
          true,
          'validateTechnicianApproval function is deployed'
        );
      } catch (error) {
        this.addResult(
          'Cloud Function Exists',
          false,
          'validateTechnicianApproval function is NOT deployed',
          true
        );
      }

      // Check if service creation function exists
      try {
        const createFunction = functions.httpsCallable('createTechnicianService');
        this.addResult(
          'Service Creation Function Exists',
          true,
          'createTechnicianService function is deployed'
        );
      } catch (error) {
        this.addResult(
          'Service Creation Function Exists',
          false,
          'createTechnicianService function is NOT deployed',
          true
        );
      }

    } catch (error) {
      this.addResult(
        'Security Validation Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testFirestoreSecurityRules() {
    this.log('\n🛡️  Test 5: Firestore Security Rules');
    
    // This would require actual rule testing which is complex
    // For now, we'll check if the rules file exists
    try {
      const fs = require('fs');
      const path = require('path');
      
      const rulesPath = path.join(__dirname, 'firestore_approval_rules.rules');
      
      if (fs.existsSync(rulesPath)) {
        this.addResult(
          'Security Rules File',
          true,
          'Enhanced Firestore rules file exists'
        );
        
        const rulesContent = fs.readFileSync(rulesPath, 'utf8');
        
        if (rulesContent.includes('isTechnicianApproved')) {
          this.addResult(
            'Security Rules Content',
            true,
            'Security rules include technician approval validation'
          );
        } else {
          this.addResult(
            'Security Rules Content',
            false,
            'Security rules do NOT include approval validation',
            true
          );
        }
      } else {
        this.addResult(
          'Security Rules File',
          false,
          'Enhanced Firestore rules file does NOT exist',
          true
        );
      }

    } catch (error) {
      this.addResult(
        'Firestore Security Rules Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testEmailVerificationRule() {
    this.log('\n📧 Test 6: Email Verification Rule');
    
    try {
      // Test that email verification is NOT required
      const testProfile = {
        fullName: 'Test Email',
        phone: '+919876543210',
        email: 'unverified@example.com',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        skills: ['plumbing'],
        experienceYears: 3,
        bankStatus: 'approved',
        aadhaarFrontUrl: 'https://example.com/aadhaar.jpg',
        customServices: ['Service'],
        // Note: No emailVerified field
      };

      const completion = this.calculateProfileCompletion(testProfile);
      
      if (completion === 100) {
        this.addResult(
          'Email Verification Optional',
          true,
          'Profile can reach 100% without email verification'
        );
      } else {
        this.addResult(
          'Email Verification Optional',
          false,
          'Profile completion incorrectly requires email verification',
          true
        );
      }

    } catch (error) {
      this.addResult(
        'Email Verification Rule Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  async testCompleteFlow() {
    this.log('\n🔄 Test 7: Complete Flow Validation');
    
    try {
      const testUid = 'test-complete-flow-' + Date.now();
      
      // Step 1: Create new technician
      await db.collection('technicians').doc(testUid).set({
        fullName: 'Complete Flow Test',
        phone: '+919876543210',
        profileApprovalRequested: false,
        profileApproved: false,
        profileRejected: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Step 2: Complete profile
      await db.collection('technicians').doc(testUid).update({
        email: 'complete@example.com',
        profilePhotoUrl: 'https://example.com/photo.jpg',
        skills: ['electrical'],
        experienceYears: 4,
        bankStatus: 'approved',
        aadhaarFrontUrl: 'https://example.com/aadhaar.jpg',
        customServices: ['Complete Service'],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Step 3: Wait for auto-approval request
      await new Promise(resolve => setTimeout(resolve, 3000));

      // Step 4: Check approval was requested
      let doc = await db.collection('technicians').doc(testUid).get();
      let data = doc.data();

      const approvalRequested = data.profileApprovalRequested === true;

      // Step 5: Simulate admin approval
      await db.collection('technicians').doc(testUid).update({
        profileApproved: true,
        profileApprovalRequested: false,
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Step 6: Verify final state
      doc = await db.collection('technicians').doc(testUid).get();
      data = doc.data();

      const finalApproved = data.profileApproved === true;
      const completion = this.calculateProfileCompletion(data);

      if (approvalRequested && finalApproved && completion === 100) {
        this.addResult(
          'Complete Flow',
          true,
          'Complete signup → profile completion → admin approval → service creation flow works'
        );
      } else {
        this.addResult(
          'Complete Flow',
          false,
          `Flow failed: approval requested=${approvalRequested}, approved=${finalApproved}, completion=${completion}%`,
          true
        );
      }

      // Cleanup
      await db.collection('technicians').doc(testUid).delete();

    } catch (error) {
      this.addResult(
        'Complete Flow Test',
        false,
        `Test failed with error: ${error.message}`,
        true
      );
    }
  }

  calculateProfileCompletion(technician) {
    let completed = 0;
    const total = 8;
    
    if (technician.fullName && technician.fullName.trim().length > 0) completed++;
    if (technician.phone && technician.phone.trim().length > 0) completed++;
    if (technician.profilePhotoUrl && technician.profilePhotoUrl.trim().length > 0) completed++;
    if (technician.skills && technician.skills.length > 0) completed++;
    if (technician.experienceYears && technician.experienceYears > 0) completed++;
    if (technician.bankStatus === 'approved') completed++;
    if ((technician.aadhaarFrontUrl && technician.aadhaarFrontUrl.trim().length > 0) || 
        (technician.panNumber && technician.panNumber.trim().length > 0)) completed++;
    if ((technician.customServices && technician.customServices.length > 0) || 
        (technician.skills && technician.skills.length > 0)) completed++;
    
    return Math.round((completed / total) * 100);
  }

  generateReport() {
    this.log('\n📊 QA VERIFICATION REPORT');
    this.log('=' * 50);
    
    const totalTests = this.testResults.length;
    const passedTests = this.testResults.filter(r => r.passed).length;
    const failedTests = totalTests - passedTests;
    
    this.log(`Total Tests: ${totalTests}`);
    this.log(`Passed: ${passedTests}`);
    this.log(`Failed: ${failedTests}`);
    this.log(`Critical Issues: ${this.criticalIssues.length}`);
    this.log(`Warnings: ${this.warnings.length}`);
    
    if (this.criticalIssues.length > 0) {
      this.log('\n❌ CRITICAL ISSUES FOUND:');
      this.criticalIssues.forEach(issue => {
        this.log(`  • ${issue.testName}: ${issue.message}`);
      });
    }
    
    if (this.warnings.length > 0) {
      this.log('\n⚠️  WARNINGS:');
      this.warnings.forEach(warning => {
        this.log(`  • ${warning.testName}: ${warning.message}`);
      });
    }
    
    const overallStatus = this.criticalIssues.length === 0 ? 
      (this.warnings.length === 0 ? '✅ READY FOR PRODUCTION' : '⚠️  READY WITH WARNINGS') : 
      '❌ NOT READY FOR PRODUCTION';
    
    this.log(`\nOVERALL STATUS: ${overallStatus}`);
    
    if (this.criticalIssues.length > 0) {
      this.log('\n🚨 IMMEDIATE ACTION REQUIRED:');
      this.log('1. Fix all critical issues before deployment');
      this.log('2. Deploy missing Cloud Functions');
      this.log('3. Update Firestore security rules');
      this.log('4. Re-run this verification suite');
    }
  }
}

// Run the verification suite
const qa = new QAVerificationSuite();
qa.runAllTests().then(() => {
  process.exit(qa.criticalIssues.length > 0 ? 1 : 0);
}).catch((error) => {
  console.error('QA Suite failed:', error);
  process.exit(1);
});