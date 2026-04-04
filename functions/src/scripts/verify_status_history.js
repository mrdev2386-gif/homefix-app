/**
 * STATUS HISTORY VERIFICATION SCRIPT
 * 
 * This script verifies that the status history tracking system is working correctly
 * across all bookings in the database.
 * 
 * Usage:
 *   node functions/src/scripts/verify_status_history.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../../scripts/serviceAccountKey.json');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Verify a single booking's status history
 */
async function verifyBooking(bookingId, bookingData) {
  const issues = [];
  const warnings = [];

  // Check 1: Does statusHistory field exist?
  if (!bookingData.statusHistory) {
    issues.push('Missing statusHistory field');
  } else if (!Array.isArray(bookingData.statusHistory)) {
    issues.push('statusHistory is not an array');
  } else if (bookingData.statusHistory.length === 0) {
    issues.push('statusHistory is empty');
  }

  // Check 2: Does current status match last history entry?
  if (bookingData.statusHistory && Array.isArray(bookingData.statusHistory) && bookingData.statusHistory.length > 0) {
    const lastEntry = bookingData.statusHistory[bookingData.statusHistory.length - 1];
    if (lastEntry.status !== bookingData.status) {
      issues.push(`Status mismatch: current="${bookingData.status}", last history="${lastEntry.status}"`);
    }
  }

  // Check 3: Are there duplicate consecutive entries?
  if (bookingData.statusHistory && Array.isArray(bookingData.statusHistory)) {
    for (let i = 1; i < bookingData.statusHistory.length; i++) {
      if (bookingData.statusHistory[i].status === bookingData.statusHistory[i - 1].status) {
        warnings.push(`Duplicate consecutive status at index ${i}: "${bookingData.statusHistory[i].status}"`);
      }
    }
  }

  // Check 4: Do all entries have timestamps?
  if (bookingData.statusHistory && Array.isArray(bookingData.statusHistory)) {
    bookingData.statusHistory.forEach((entry, index) => {
      if (!entry.timestamp) {
        warnings.push(`Missing timestamp at index ${index}`);
      }
    });
  }

  return { issues, warnings };
}

/**
 * Main verification function
 */
async function verifyAllBookings() {
  log('\n========================================', 'cyan');
  log('STATUS HISTORY VERIFICATION SCRIPT', 'cyan');
  log('========================================\n', 'cyan');

  try {
    // Fetch all bookings
    log('📊 Fetching all bookings...', 'blue');
    const bookingsSnapshot = await db.collection('bookings').get();
    
    if (bookingsSnapshot.empty) {
      log('⚠️  No bookings found in database', 'yellow');
      return;
    }

    log(`✅ Found ${bookingsSnapshot.size} bookings\n`, 'green');

    // Statistics
    let totalBookings = 0;
    let bookingsWithHistory = 0;
    let bookingsWithoutHistory = 0;
    let bookingsWithIssues = 0;
    let bookingsWithWarnings = 0;
    let totalHistoryEntries = 0;

    const issuesList = [];
    const warningsList = [];

    // Verify each booking
    for (const doc of bookingsSnapshot.docs) {
      totalBookings++;
      const bookingData = doc.data();
      const bookingId = doc.id;

      const { issues, warnings } = await verifyBooking(bookingId, bookingData);

      if (bookingData.statusHistory && Array.isArray(bookingData.statusHistory)) {
        bookingsWithHistory++;
        totalHistoryEntries += bookingData.statusHistory.length;
      } else {
        bookingsWithoutHistory++;
      }

      if (issues.length > 0) {
        bookingsWithIssues++;
        issuesList.push({ bookingId, issues });
      }

      if (warnings.length > 0) {
        bookingsWithWarnings++;
        warningsList.push({ bookingId, warnings });
      }
    }

    // Print summary
    log('========================================', 'cyan');
    log('VERIFICATION SUMMARY', 'cyan');
    log('========================================\n', 'cyan');

    log(`📊 Total Bookings: ${totalBookings}`, 'blue');
    log(`✅ Bookings with History: ${bookingsWithHistory} (${((bookingsWithHistory / totalBookings) * 100).toFixed(1)}%)`, 'green');
    log(`❌ Bookings without History: ${bookingsWithoutHistory} (${((bookingsWithoutHistory / totalBookings) * 100).toFixed(1)}%)`, bookingsWithoutHistory > 0 ? 'red' : 'green');
    log(`📈 Total History Entries: ${totalHistoryEntries}`, 'blue');
    log(`📊 Average Entries per Booking: ${(totalHistoryEntries / bookingsWithHistory).toFixed(2)}`, 'blue');
    log(`⚠️  Bookings with Issues: ${bookingsWithIssues}`, bookingsWithIssues > 0 ? 'red' : 'green');
    log(`⚠️  Bookings with Warnings: ${bookingsWithWarnings}`, bookingsWithWarnings > 0 ? 'yellow' : 'green');

    // Print issues
    if (issuesList.length > 0) {
      log('\n========================================', 'red');
      log('ISSUES FOUND', 'red');
      log('========================================\n', 'red');

      issuesList.forEach(({ bookingId, issues }) => {
        log(`\n🔴 Booking: ${bookingId}`, 'red');
        issues.forEach(issue => {
          log(`   - ${issue}`, 'red');
        });
      });
    }

    // Print warnings
    if (warningsList.length > 0) {
      log('\n========================================', 'yellow');
      log('WARNINGS FOUND', 'yellow');
      log('========================================\n', 'yellow');

      warningsList.forEach(({ bookingId, warnings }) => {
        log(`\n⚠️  Booking: ${bookingId}`, 'yellow');
        warnings.forEach(warning => {
          log(`   - ${warning}`, 'yellow');
        });
      });
    }

    // Print recommendations
    log('\n========================================', 'cyan');
    log('RECOMMENDATIONS', 'cyan');
    log('========================================\n', 'cyan');

    if (bookingsWithoutHistory > 0) {
      log('📝 Run migration script to initialize history for old bookings:', 'yellow');
      log('   node functions/src/scripts/migrate_booking_status_history.js\n', 'cyan');
    }

    if (bookingsWithIssues > 0) {
      log('🔧 Fix status mismatches by running integrity check:', 'yellow');
      log('   Use validateStatusHistoryIntegrity() function\n', 'cyan');
    }

    if (bookingsWithWarnings > 0) {
      log('⚠️  Review duplicate entries - may indicate manual updates', 'yellow');
    }

    if (bookingsWithoutHistory === 0 && bookingsWithIssues === 0) {
      log('✅ All bookings have valid status history!', 'green');
      log('✅ System is working correctly!', 'green');
    }

    log('\n========================================', 'cyan');
    log('VERIFICATION COMPLETE', 'cyan');
    log('========================================\n', 'cyan');

  } catch (error) {
    log(`\n❌ Error during verification: ${error.message}`, 'red');
    console.error(error);
    process.exit(1);
  }
}

/**
 * Sample booking status history display
 */
async function displaySampleHistory(limit = 5) {
  log('\n========================================', 'cyan');
  log('SAMPLE STATUS HISTORIES', 'cyan');
  log('========================================\n', 'cyan');

  try {
    const bookingsSnapshot = await db.collection('bookings')
      .where('statusHistory', '!=', null)
      .limit(limit)
      .get();

    if (bookingsSnapshot.empty) {
      log('⚠️  No bookings with history found', 'yellow');
      return;
    }

    bookingsSnapshot.forEach((doc, index) => {
      const bookingData = doc.data();
      log(`\n📋 Booking ${index + 1}: ${doc.id}`, 'blue');
      log(`   Current Status: ${bookingData.status}`, 'cyan');
      log(`   History (${bookingData.statusHistory.length} entries):`, 'cyan');
      
      bookingData.statusHistory.forEach((entry, idx) => {
        const timestamp = entry.timestamp?.toDate?.() || 'N/A';
        log(`      ${idx + 1}. ${entry.status} - ${timestamp}`, 'green');
      });
    });

  } catch (error) {
    log(`\n❌ Error displaying samples: ${error.message}`, 'red');
  }
}

/**
 * Run verification
 */
async function main() {
  await verifyAllBookings();
  await displaySampleHistory(3);
  process.exit(0);
}

// Execute
main().catch(error => {
  log(`\n❌ Fatal error: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});
