// Run migration using firebase-functions-test with offline mode
const functionsTest = require('firebase-functions-test')(
  { projectId: 'homefix-aa42d' },
  null // No credentials needed for offline test
);

const admin = require('firebase-admin');

// Initialize admin for actual Firestore access
const serviceAccount = require('../scripts/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Import the function
const { migrateServicesToNested } = require('./lib/admin/services');

async function runMigration() {
  try {
    console.log('Creating mock context with admin claims...');
    
    // Create wrapped function
    const wrapped = functionsTest.wrap(migrateServicesToNested);
    
    // Create mock context with admin
    const mockContext = {
      auth: {
        uid: 'test-admin-uid',
        token: {
          admin: true,
          email: 'admin@homefix.com',
          user_id: 'test-admin-uid'
        }
      }
    };
    
    console.log('Calling migrateServicesToNested with admin context...');
    console.log('Targeting project: homefix-aa42d');
    
    // Call the function
    const result = await wrapped({}, mockContext);
    
    console.log('\n=== MIGRATION COMPLETE ===');
    console.log('Full response:', JSON.stringify(result, null, 2));
    
    // Extract the data
    console.log('\n=== EXECUTION RESULT ===');
    console.log(`totalRootServices: ${result.totalRootServices}`);
    console.log(`totalMigrated: ${result.totalMigrated}`);
    console.log(`totalSkippedAlreadyExists: ${result.totalSkippedAlreadyExists}`);
    console.log(`totalErrors: ${result.totalErrors}`);
    
    console.log('\n=== NESTED VERIFICATION (Manual) ===');
    console.log('Please check Firestore console to verify:');
    console.log('- categories/{categoryId}/services - nested services');
    console.log('- Count total nested services and categories with services');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

runMigration();
