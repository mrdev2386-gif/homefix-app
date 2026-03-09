/**
 * Backfill Customer Locations Migration Script
 * 
 * This script fixes existing customer data by:
 * 1. Creating addresses with state/district from customer documents
 * 2. Setting primaryAddressId on customer documents
 * 3. Updating existing addresses with missing state/district
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';

if (!admin.apps.length) {
    try {
        const serviceAccount = require(SERVICE_ACCOUNT_PATH);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log('✅ Firebase Admin initialized\n');
    } catch (error) {
        console.error('❌ Error initializing Firebase Admin:', error.message);
        process.exit(1);
    }
}

const db = admin.firestore();

// ============================================================================
// MIGRATION LOGIC
// ============================================================================

async function backfillCustomerLocations() {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔧 BACKFILL CUSTOMER LOCATIONS MIGRATION');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    try {
        const customersSnap = await db.collection('customers').get();
        console.log(`📊 Found ${customersSnap.size} customers\n`);

        let processed = 0;
        let addressesCreated = 0;
        let addressesUpdated = 0;
        let primaryAddressSet = 0;
        let skipped = 0;
        let errors = 0;

        for (const customerDoc of customersSnap.docs) {
            const customerId = customerDoc.id;
            const customerData = customerDoc.data();

            try {
                console.log(`\n📍 Processing customer: ${customerId}`);

                const state = customerData.state;
                const district = customerData.district;
                const primaryAddressId = customerData.primaryAddressId;

                // Check if customer has location data
                if (!state || !district) {
                    console.log(`   ⚠️  No state/district in customer document - skipping`);
                    skipped++;
                    continue;
                }

                console.log(`   📍 Location: ${state} / ${district}`);

                // Get existing addresses
                const addressesSnap = await customerDoc.ref.collection('addresses').get();
                console.log(`   📋 Existing addresses: ${addressesSnap.size}`);

                if (addressesSnap.empty) {
                    // Create new address with state/district
                    const addressId = customerDoc.ref.collection('addresses').doc().id;
                    
                    await customerDoc.ref.collection('addresses').doc(addressId).set({
                        id: addressId,
                        label: 'Home',
                        state: state,
                        district: district,
                        fullAddress: `${district}, ${state}`,
                        city: district,
                        isDefault: true,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });

                    // Set primaryAddressId
                    await customerDoc.ref.update({
                        primaryAddressId: addressId,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });

                    console.log(`   ✅ Created address ${addressId}`);
                    console.log(`   ✅ Set primaryAddressId`);
                    addressesCreated++;
                    primaryAddressSet++;
                } else {
                    // Update existing addresses with state/district if missing
                    const batch = db.batch();
                    let needsUpdate = false;
                    let foundPrimary = false;

                    for (const addressDoc of addressesSnap.docs) {
                        const addressData = addressDoc.data();
                        
                        if (!addressData.state || !addressData.district) {
                            batch.update(addressDoc.ref, {
                                state: state,
                                district: district,
                            });
                            console.log(`   ✅ Updating address ${addressDoc.id} with location`);
                            needsUpdate = true;
                            addressesUpdated++;
                        }

                        if (addressData.isDefault) {
                            foundPrimary = true;
                        }
                    }

                    // Set primaryAddressId if missing
                    if (!primaryAddressId) {
                        const firstAddressId = foundPrimary 
                            ? addressesSnap.docs.find(doc => doc.data().isDefault)?.id
                            : addressesSnap.docs[0].id;

                        if (firstAddressId) {
                            batch.update(customerDoc.ref, {
                                primaryAddressId: firstAddressId,
                                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                            });
                            console.log(`   ✅ Set primaryAddressId to ${firstAddressId}`);
                            primaryAddressSet++;
                            needsUpdate = true;
                        }
                    }

                    if (needsUpdate) {
                        await batch.commit();
                    } else {
                        console.log(`   ℹ️  No updates needed`);
                    }
                }

                processed++;
            } catch (error) {
                console.error(`   ❌ Error processing customer ${customerId}:`, error.message);
                errors++;
            }
        }

        // Summary
        console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('📊 MIGRATION SUMMARY');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        console.log(`Total Customers: ${customersSnap.size}`);
        console.log(`Processed: ${processed}`);
        console.log(`Addresses Created: ${addressesCreated}`);
        console.log(`Addresses Updated: ${addressesUpdated}`);
        console.log(`Primary Address Set: ${primaryAddressSet}`);
        console.log(`Skipped (no location): ${skipped}`);
        console.log(`Errors: ${errors}`);
        console.log();

        if (errors === 0) {
            console.log('✅ MIGRATION COMPLETED SUCCESSFULLY\n');
        } else {
            console.log(`⚠️  MIGRATION COMPLETED WITH ${errors} ERRORS\n`);
        }

    } catch (error) {
        console.error('\n❌ MIGRATION FAILED:', error.message);
        console.error(error);
    }

    process.exit(0);
}

// Run the migration
backfillCustomerLocations();
