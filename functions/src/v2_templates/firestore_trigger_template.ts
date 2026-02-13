/**
 * v2 Firestore Trigger Function Templates
 * Migration from: functions.firestore.document().onCreate/onUpdate
 */

import {
    onDocumentCreated,
    onDocumentUpdated,
    onDocumentDeleted,
    onDocumentWritten,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * v2 onDocumentCreated Trigger
 * 
 * Key Changes from v1:
 * 1. Import from 'firebase-functions/v2/firestore'
 * 2. Use document pattern directly: "collection/{docId}"
 * 3. Access data via event.data instead of snapshot
 * 4. Access params via event.params instead of context.params
 */
export const onBookingCreated = onDocumentCreated(
    {
        document: "bookings/{bookingId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 100,
    },
    async (event: any) => {
        // v2: Access data via event.data
        const snapshot = event.data;
        if (!snapshot) {
            console.log("No document associated with the event");
            return;
        }

        const booking = snapshot.data();
        const bookingId = event.params.bookingId;

        console.log(`New booking created: ${bookingId}`);

        try {
            // 1. Send notification to customer
            await db.collection("notifications").add({
                userId: booking.customerId,
                title: "Booking Received",
                body: `Your booking for ${booking.serviceTitle} has been received.`,
                type: "booking_created",
                bookingId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 2. Add to matching queue if payment confirmed
            if (booking.paymentStatus === "paid" || booking.paymentStatus === "authorized") {
                await db.collection("matching_queue").add({
                    bookingId,
                    priority: "normal",
                    serviceCategory: booking.services?.[0]?.category || "general",
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            // 3. Notify technician if already assigned
            if (booking.assignedTechnicianId) {
                await db.collection("notifications").add({
                    userId: booking.assignedTechnicianId,
                    title: "New Job Assigned!",
                    body: `You have a new booking for ${booking.serviceTitle}.`,
                    type: "job_assigned",
                    bookingId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            console.log(`Booking ${bookingId} processed successfully`);
            return;
        } catch (error: any) {
            console.error(`Error processing booking ${bookingId}:`, error);
            throw error;
        }
    }
);

/**
 * v2 onDocumentUpdated Trigger
 */
export const onBookingStatusChange = onDocumentUpdated(
    {
        document: "bookings/{bookingId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 100,
    },
    async (event: any) => {
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();
        const bookingId = event.params.bookingId;

        if (!beforeData || !afterData) {
            console.log("Missing before or after data");
            return;
        }

        const statusChanged = beforeData.status !== afterData.status;
        const technicianAssigned = !beforeData.assignedTechnicianId && afterData.assignedTechnicianId;

        if (!statusChanged && !technicianAssigned) {
            return; // No relevant changes
        }

        console.log(`Booking ${bookingId} updated: ${beforeData.status} → ${afterData.status}`);

        try {
            // Handle status-specific logic
            if (statusChanged) {
                await handleStatusChangeNotification(bookingId, beforeData.status, afterData.status, afterData);
            }

            // Handle technician assignment
            if (technicianAssigned) {
                await handleTechnicianAssignment(bookingId, afterData);
            }

            // Handle completion - process technician earnings
            if (afterData.status === "completed" && beforeData.status !== "completed") {
                await processTechnicianEarnings(bookingId, afterData);
            }

            return;
        } catch (error: any) {
            console.error(`Error processing booking update ${bookingId}:`, error);
            throw error;
        }
    }
);

/**
 * Handle status change notifications
 */
async function handleStatusChangeNotification(
    bookingId: string,
    oldStatus: string,
    newStatus: string,
    booking: any
): Promise<void> {
    const batch = db.batch();

    const notificationRef = db.collection("notifications").doc();
    const notificationData: any = {
        userId: booking.customerId,
        type: `booking_${newStatus}`,
        bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    switch (newStatus) {
        case "confirmed":
            notificationData.title = "Booking Confirmed!";
            notificationData.body = `Your booking for ${booking.serviceTitle} is confirmed.`;
            break;
        case "assigned":
            notificationData.title = "Technician Assigned";
            notificationData.body = `Expert ${booking.assignedTechnicianName} has been assigned to your service.`;
            break;
        case "on_the_way":
            notificationData.title = "Technician is On The Way!";
            notificationData.body = "Get ready! Our professional is headed to your location.";
            break;
        case "started":
            notificationData.title = "Service Started";
            notificationData.body = "The pro has started the service. Relax while we fix it!";
            break;
        case "completed":
            notificationData.title = "Service Completed!";
            notificationData.body = "How was your experience? Please rate the service.";
            break;
        case "cancelled":
            notificationData.title = "Booking Cancelled";
            notificationData.body = `Your booking for ${booking.serviceTitle} was cancelled.`;
            break;
        default:
            return;
    }

    batch.set(notificationRef, notificationData);
    await batch.commit();
}

/**
 * Handle technician assignment notification
 */
async function handleTechnicianAssignment(bookingId: string, booking: any): Promise<void> {
    if (!booking.assignedTechnicianId) return;

    await db.collection("notifications").add({
        userId: booking.assignedTechnicianId,
        title: "New Job Request",
        body: `New job request for ${booking.serviceTitle} at ${booking.scheduledTime}.`,
        type: "job_request",
        bookingId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Process technician earnings on completion
 */
async function processTechnicianEarnings(bookingId: string, booking: any): Promise<void> {
    if (!booking.assignedTechnicianId) return;

    const technicianEarnings = booking.finalAmount * 0.8; // 80% to technician

    await db.runTransaction(async (transaction) => {
        // Add to technician wallet
        const walletRef = db.collection("technician_wallets").doc(booking.assignedTechnicianId);
        const walletDoc = await transaction.get(walletRef);

        const currentBalance = walletDoc?.data()?.balance || 0;

        transaction.set(walletRef, {
            technicianId: booking.assignedTechnicianId,
            balance: currentBalance + technicianEarnings,
            totalEarnings: (walletDoc?.data()?.totalEarnings || 0) + technicianEarnings,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Add transaction record
        const txRef = db.collection("wallet_transactions").doc();
        transaction.set(txRef, {
            technicianId: booking.assignedTechnicianId,
            bookingId,
            amount: technicianEarnings,
            type: "earning",
            description: `Earnings from booking ${bookingId}`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

    console.log(`Processed ₹${technicianEarnings} earnings for technician ${booking.assignedTechnicianId}`);
}

/**
 * v2 onDocumentDeleted Trigger
 */
export const onBookingDeleted = onDocumentDeleted(
    {
        document: "bookings/{bookingId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 30,
        minInstances: 1,
        maxInstances: 50,
    },
    async (event: any) => {
        const bookingId = event.params.bookingId;
        const deletedData = event.data?.data();

        console.log(`Booking ${bookingId} deleted`);

        // Cleanup related documents if needed
        if (deletedData) {
            // Cancel any pending matches
            const pendingMatches = await db.collection("matching_queue")
                .where("bookingId", "==", bookingId)
                .get();

            const batch = db.batch();
            pendingMatches.docs.forEach((doc: any) => {
                batch.delete(doc.ref);
            });
            await batch.commit();
        }
    }
);

/**
 * v2 onDocumentWritten Trigger (handles create, update, delete)
 */
export const onBookingWritten = onDocumentWritten(
    {
        document: "bookings/{bookingId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 60,
        minInstances: 1,
        maxInstances: 100,
    },
    async (event: any) => {
        const before = event.data?.before?.data();
        const after = event.data?.after?.data();
        const bookingId = event.params.bookingId;

        if (!before && !after) {
            return; // No change
        }

        if (after && !before) {
            // Document created
            console.log(`Booking ${bookingId} created`);
        } else if (!after && before) {
            // Document deleted
            console.log(`Booking ${bookingId} deleted`);
        } else if (before && after) {
            // Document updated
            console.log(`Booking ${bookingId} updated`);
        }
    }
);

/**
 * v2 onDocumentUpdated for technician applications
 */
export const onTechnicianApplicationUpdate = onDocumentUpdated(
    {
        document: "technician_applications/{appId}",
        region: "us-central1",
        memory: "256MiB",
        timeoutSeconds: 30,
        minInstances: 1,
        maxInstances: 50,
    },
    async (event: any) => {
        const after = event.data.after.data();
        const before = event.data.before.data();

        if (!after || !before) return;

        if (before.status !== after.status) {
            const userId = event.params.appId;
            let title = "Application Update";
            let body = `Your application status is now: ${after.status}`;

            if (after.status === "approved") {
                title = "Application Approved";
                body = "Congratulations! Your technician application has been approved.";
            } else if (after.status === "rejected") {
                title = "Application Rejected";
                body = "We're sorry, your technician application was not approved.";
            }

            await db.collection("notifications").add({
                userId,
                title,
                body,
                type: "application_status",
                status: after.status,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
);
