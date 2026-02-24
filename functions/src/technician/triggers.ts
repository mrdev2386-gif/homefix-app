
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Sync technician approval status to all their services
 * When a technician is approved/suspended, update all their service listings
 */
export const syncTechnicianApprovalToServices = functions.firestore
    .document('technicians/{techId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (!before || !after) return;

        // Check if isApproved status changed
        if (before.isApproved !== after.isApproved) {
            const techId = context.params.techId;
            const isApproved = after.isApproved;

            console.log(`[TRIGGER] Technician ${techId} isApproved changed from ${before.isApproved} to ${isApproved}. Syncing to services...`);

            const servicesSnap = await db.collection('technician_services')
                .where('technicianId', '==', techId)
                .get();

            if (servicesSnap.empty) {
                console.log(`[TRIGGER] No services found for technician ${techId}`);
                return;
            }

            const batch = db.batch();
            servicesSnap.docs.forEach(doc => {
                batch.update(doc.ref, {
                    technicianApproved: isApproved,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });

            await batch.commit();
            console.log(`[TRIGGER] Updated ${servicesSnap.size} services for technician ${techId} with technicianApproved=${isApproved}`);
        }
    });
