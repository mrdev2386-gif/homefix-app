/**
 * CLEANUP DUPLICATE CUSTOMER
 * 
 * Removes duplicate customer account and reassigns any bookings to primary account
 * 
 * Primary UID: S8EAzPS1nfho2dspOxy0JJHQnJ12
 * Duplicate UID: 4IxIlemh7ig4vUbg4qpgiMKeEeE3
 * 
 * Usage:
 * npx ts-node src/payments/cleanupDuplicateCustomer.ts
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin
if (!admin.apps.length) {
    const serviceAccount = require('../../serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://homefix-aa42d.firebaseio.com'
    });
}

const db = admin.firestore();

const PRIMARY_UID = 'S8EAzPS1nfho2dspOxy0JJHQnJ12';
const DUPLICATE_UID = '4IxIlemh7ig4vUbg4qpgiMKeEeE3';

async function cleanupDuplicateCustomer() {
    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                     CLEANUP DUPLICATE CUSTOMER                             ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝\n');
    
    try {
        // Step 1: Verify primary customer exists
        console.log('Step 1: Verifying primary customer...');
        const primaryDoc = await db.collection('customers').doc(PRIMARY_UID).get();
        
        if (!primaryDoc.exists) {
            throw new Error(`Primary customer ${PRIMARY_UID} not found!`);
        }
        
        const primaryData = primaryDoc.data()!;
        console.log(`✔ Primary customer found: ${primaryData.name || primaryData.displayName || 'N/A'}`);
        console.log(`  Email: ${primaryData.email || 'N/A'}`);
        
        // Step 2: Check if duplicate exists
        console.log('\nStep 2: Checking duplicate customer...');
        const duplicateDoc = await db.collection('customers').doc(DUPLICATE_UID).get();
        
        if (!duplicateDoc.exists) {
            console.log('✔ Duplicate customer already removed or does not exist');
            return;
        }
        
        const duplicateData = duplicateDoc.data()!;
        console.log(`⚠ Duplicate customer found: ${duplicateData.name || duplicateData.displayName || 'N/A'}`);
        console.log(`  Email: ${duplicateData.email || 'N/A'}`);
        
        // Step 3: Check for bookings referencing duplicate UID
        console.log('\nStep 3: Checking for bookings with duplicate UID...');
        const bookingsSnapshot = await db.collection('bookings')
            .where('customerId', '==', DUPLICATE_UID)
            .get();
        
        if (!bookingsSnapshot.empty) {
            console.log(`⚠ Found ${bookingsSnapshot.size} booking(s) referencing duplicate UID`);
            
            // Reassign bookings to primary UID
            console.log('\nStep 4: Reassigning bookings to primary UID...');
            const batch = db.batch();
            
            bookingsSnapshot.docs.forEach((doc) => {
                const bookingData = doc.data();
                console.log(`  - Reassigning booking ${doc.id} (${bookingData.bookingNumber || 'N/A'})`);
                batch.update(doc.ref, {
                    customerId: PRIMARY_UID,
                    customerName: primaryData.name || primaryData.displayName || bookingData.customerName,
                    customerEmail: primaryData.email || bookingData.customerEmail,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    _migrationNote: `Reassigned from duplicate UID ${DUPLICATE_UID} to primary UID ${PRIMARY_UID}`
                });
            });
            
            await batch.commit();
            console.log(`✔ Successfully reassigned ${bookingsSnapshot.size} booking(s)`);
        } else {
            console.log('✔ No bookings found referencing duplicate UID');
        }
        
        // Step 5: Check for other collections that might reference the duplicate
        console.log('\nStep 5: Checking other collections...');
        
        // Check addresses
        const addressesSnapshot = await db.collection('addresses')
            .where('userId', '==', DUPLICATE_UID)
            .get();
        
        if (!addressesSnapshot.empty) {
            console.log(`⚠ Found ${addressesSnapshot.size} address(es) referencing duplicate UID`);
            const addressBatch = db.batch();
            
            addressesSnapshot.docs.forEach((doc) => {
                console.log(`  - Reassigning address ${doc.id}`);
                addressBatch.update(doc.ref, {
                    userId: PRIMARY_UID,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });
            
            await addressBatch.commit();
            console.log(`✔ Successfully reassigned ${addressesSnapshot.size} address(es)`);
        } else {
            console.log('✔ No addresses found referencing duplicate UID');
        }
        
        // Check notifications
        const notificationsSnapshot = await db.collection('notifications')
            .where('userId', '==', DUPLICATE_UID)
            .get();
        
        if (!notificationsSnapshot.empty) {
            console.log(`⚠ Found ${notificationsSnapshot.size} notification(s) referencing duplicate UID`);
            const notifBatch = db.batch();
            
            notificationsSnapshot.docs.forEach((doc) => {
                notifBatch.update(doc.ref, {
                    userId: PRIMARY_UID,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });
            
            await notifBatch.commit();
            console.log(`✔ Successfully reassigned ${notificationsSnapshot.size} notification(s)`);
        } else {
            console.log('✔ No notifications found referencing duplicate UID');
        }
        
        // Step 6: Delete duplicate customer document
        console.log('\nStep 6: Deleting duplicate customer document...');
        await db.collection('customers').doc(DUPLICATE_UID).delete();
        console.log('✔ Duplicate customer document deleted');
        
        // Step 7: Log the cleanup
        console.log('\nStep 7: Logging cleanup action...');
        await db.collection('admin_logs').add({
            action: 'duplicate_customer_cleanup',
            primaryUid: PRIMARY_UID,
            duplicateUid: DUPLICATE_UID,
            bookingsReassigned: bookingsSnapshot.size,
            addressesReassigned: addressesSnapshot.size,
            notificationsReassigned: notificationsSnapshot.size,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            performedBy: 'system_cleanup_script'
        });
        console.log('✔ Cleanup action logged');
        
        // Final summary
        console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
        console.log('║                          CLEANUP COMPLETE                                  ║');
        console.log('╚════════════════════════════════════════════════════════════════════════════╝');
        console.log(`\n✔ Primary UID: ${PRIMARY_UID}`);
        console.log(`✔ Duplicate UID removed: ${DUPLICATE_UID}`);
        console.log(`✔ Bookings reassigned: ${bookingsSnapshot.size}`);
        console.log(`✔ Addresses reassigned: ${addressesSnapshot.size}`);
        console.log(`✔ Notifications reassigned: ${notificationsSnapshot.size}`);
        console.log('\n✔ System now has single source of truth for customer identity');
        
    } catch (error: any) {
        console.error('\n✖ CLEANUP FAILED:', error.message);
        console.error(error);
        process.exit(1);
    }
}

// Run cleanup
cleanupDuplicateCustomer()
    .then(() => {
        console.log('\n✔ Script completed successfully');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n✖ Script failed:', error);
        process.exit(1);
    });
