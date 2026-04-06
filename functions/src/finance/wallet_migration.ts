/**
 * Wallet Migration Utility
 * FIX 2: WALLET MIGRATION CHECK
 * 
 * Migrates old wallet data to new technician_wallets structure
 * Ensures single source of truth
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin } from '../shared/utils';

const LOG_PREFIX = '[WALLET_MIGRATION]';

/**
 * Migrate a single technician's wallet data
 * FIX 2: Check old fields and migrate to technician_wallets
 */
async function migrateTechnicianWallet(technicianId: string): Promise<{
    migrated: boolean;
    oldBalance?: number;
    newBalance?: number;
    error?: string;
}> {
    try {
        const techRef = db.collection('technicians').doc(technicianId);
        const walletRef = db.collection('technician_wallets').doc(technicianId);

        const [techDoc, walletDoc] = await Promise.all([
            techRef.get(),
            walletRef.get()
        ]);

        if (!techDoc.exists) {
            return { migrated: false, error: 'Technician not found' };
        }

        const techData = techDoc.data()!;
        
        // Check if old wallet balance exists
        const oldBalance = techData.walletBalance;
        const oldTotalEarnings = techData.totalEarnings || 0;

        if (oldBalance === undefined) {
            // No old wallet data to migrate
            return { migrated: false, error: 'No old wallet data found' };
        }

        // Check if new wallet already exists
        if (walletDoc.exists) {
            const walletData = walletDoc.data()!;
            console.log(`${LOG_PREFIX} Wallet already exists for ${technicianId}, removing old fields only`);
            
            // Remove old fields only
            await techRef.update({
                walletBalance: admin.firestore.FieldValue.delete(),
                totalEarnings: admin.firestore.FieldValue.delete()
            });

            return {
                migrated: true,
                oldBalance,
                newBalance: walletData.availableBalance
            };
        }

        // Migrate to new wallet structure
        await walletRef.set({
            availableBalance: oldBalance || 0,
            pendingBalance: 0,
            lifetimeEarnings: oldTotalEarnings,
            lastPayoutAt: null,
            migratedFrom: 'technicians.walletBalance',
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Remove old fields
        await techRef.update({
            walletBalance: admin.firestore.FieldValue.delete(),
            totalEarnings: admin.firestore.FieldValue.delete()
        });

        console.log(`${LOG_PREFIX} Migrated wallet for ${technicianId}: ₹${oldBalance}`);

        return {
            migrated: true,
            oldBalance,
            newBalance: oldBalance
        };

    } catch (error: any) {
        console.error(`${LOG_PREFIX} Migration error for ${technicianId}:`, error);
        return {
            migrated: false,
            error: error.message
        };
    }
}

/**
 * Admin function to migrate all technician wallets
 * FIX 2: Batch migration utility
 */
export const migrateAllWallets = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
        await assertAdmin(context);

        const { batchSize = 50, dryRun = false } = data;

        console.log(`${LOG_PREFIX} Starting wallet migration (dryRun: ${dryRun})`);

        const results = {
            total: 0,
            migrated: 0,
            skipped: 0,
            errors: 0,
            details: [] as any[]
        };

        try {
            // Get all technicians with old wallet balance
            const techniciansSnapshot = await db.collection('technicians')
                .where('walletBalance', '>=', 0)
                .limit(batchSize)
                .get();

            results.total = techniciansSnapshot.size;

            for (const techDoc of techniciansSnapshot.docs) {
                const techId = techDoc.id;
                const techData = techDoc.data();

                if (dryRun) {
                    // Dry run - just report what would be migrated
                    results.details.push({
                        technicianId: techId,
                        oldBalance: techData.walletBalance,
                        action: 'would_migrate'
                    });
                    results.migrated++;
                } else {
                    // Actually migrate
                    const result = await migrateTechnicianWallet(techId);
                    
                    if (result.migrated) {
                        results.migrated++;
                        results.details.push({
                            technicianId: techId,
                            oldBalance: result.oldBalance,
                            newBalance: result.newBalance,
                            action: 'migrated'
                        });
                    } else if (result.error) {
                        results.errors++;
                        results.details.push({
                            technicianId: techId,
                            error: result.error,
                            action: 'error'
                        });
                    } else {
                        results.skipped++;
                    }
                }
            }

            console.log(`${LOG_PREFIX} Migration complete:`, results);

            return {
                success: true,
                ...results
            };

        } catch (error: any) {
            console.error(`${LOG_PREFIX} Batch migration error:`, error);
            throw new functions.https.HttpsError('internal', error.message);
        }
    });

/**
 * Admin function to migrate a single technician's wallet
 * FIX 2: Single migration utility
 */
export const migrateSingleWallet = functions
    .region('asia-south1')
    .https.onCall(async (data, context) => {
        await assertAdmin(context);

        const { technicianId } = data;

        if (!technicianId) {
            throw new functions.https.HttpsError('invalid-argument', 'technicianId required');
        }

        const result = await migrateTechnicianWallet(technicianId);

        if (result.migrated) {
            return {
                success: true,
                message: `Wallet migrated successfully for ${technicianId}`,
                ...result
            };
        } else {
            throw new functions.https.HttpsError('failed-precondition', result.error || 'Migration failed');
        }
    });

/**
 * Check if a technician needs wallet migration
 * FIX 2: Migration check utility
 */
export async function checkWalletMigrationNeeded(technicianId: string): Promise<boolean> {
    try {
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        
        if (!techDoc.exists) {
            return false;
        }

        const techData = techDoc.data()!;
        
        // Check if old wallet balance exists
        return techData.walletBalance !== undefined;
    } catch (error) {
        console.error(`${LOG_PREFIX} Check migration error:`, error);
        return false;
    }
}

/**
 * Auto-migrate wallet if needed before any wallet operation
 * FIX 2: Automatic migration on first access
 */
export async function autoMigrateWalletIfNeeded(technicianId: string): Promise<void> {
    const needsMigration = await checkWalletMigrationNeeded(technicianId);
    
    if (needsMigration) {
        console.log(`${LOG_PREFIX} Auto-migrating wallet for ${technicianId}`);
        const result = await migrateTechnicianWallet(technicianId);
        
        if (!result.migrated) {
            console.error(`${LOG_PREFIX} Auto-migration failed for ${technicianId}:`, result.error);
        }
    }
}
