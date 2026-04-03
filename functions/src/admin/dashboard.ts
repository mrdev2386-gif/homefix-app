import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin } from './utils';
import { secureCallable } from '../shared/security';

export const getDashboardStats = functions.region('asia-south1').https.onCall(
    secureCallable(async (data: any, context: any) => {
    try {
        await assertAdmin(context);

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        // const todayStr = today.toISOString();

        console.log('[Dashboard] Fetching stats...');

        // Helper to safely execute count queries
        const safeCount = async (query: FirebaseFirestore.Query) => {
            try {
                const snapshot = await query.count().get();
                return snapshot.data().count || 0;
            } catch (e) {
                console.error('Failed to get count:', e);
                return 0; // Default to zero on error
            }
        };

        // Perform queries in parallel
        const [
            totalCustomers,
            totalTechnicians,
            totalBookingsToday,
            pendingBookings,
            confirmedBookings,
            activeBookings,
            completedBookings,
            cancelledBookings,
            pendingKYC,
            onlineTechs
        ] = await Promise.all([
            safeCount(db.collection('customers')),
            safeCount(db.collection('technicians')),
            safeCount(db.collection('bookings').where('createdAt', '>=', today)),
            safeCount(db.collection('bookings').where('status', '==', 'pending_payment')),
            safeCount(db.collection('bookings').where('status', '==', 'confirmed')),
            safeCount(db.collection('bookings').where('status', 'in', ['assigned', 'on_the_way', 'started'])),
            safeCount(db.collection('bookings').where('status', '==', 'completed')),
            safeCount(db.collection('bookings').where('status', '==', 'cancelled')),
            safeCount(db.collection('technicians').where('status', '==', 'pending')),
            safeCount(db.collection('technicians').where('isAvailable', '==', true))
        ]);

        // Revenue & Payout calculations
        let revenueToday = 0;
        let totalRevenue = 0;
        let platformEarningsTotal = 0;
        let technicianPayoutsTotal = 0;

        try {
            const revenueTodaySnap = await db.collection('bookings')
                .where('paymentStatus', '==', 'paid')
                .where('createdAt', '>=', today)
                .get();

            revenueTodaySnap.forEach(doc => {
                const amount = Number(doc.data().finalAmount || doc.data().price || 0);
                revenueToday += amount;
            });

            // Aggregate Platform Earnings and Payouts
            const paidBookingsSnap = await db.collection('bookings')
                .where('paymentStatus', '==', 'paid')
                .get();

            paidBookingsSnap.forEach(doc => {
                const data = doc.data();
                const amount = Number(data.finalAmount || data.price || 0);
                totalRevenue += amount;
                platformEarningsTotal += Number(data.platformCommission || (amount * 0.10));
                technicianPayoutsTotal += Number(data.technicianPayout || (amount * 0.90));
            });

        } catch (e) {
            console.error('Failed to calculate revenue:', e);
        }

        // Get recent bookings safely
        let recentActivity: any[] = [];
        try {
            const recentSnap = await db.collection('bookings')
                .orderBy('createdAt', 'desc')
                .limit(10)
                .get();

            recentActivity = recentSnap.docs.map(d => {
                const data = d.data();
                return {
                    id: d.id,
                    customerName: data.customerName || 'Unknown',
                    serviceTitle: data.serviceName || data.serviceTitle || 'Service',
                    amount: data.finalAmount || data.price || 0,
                    status: data.status || 'unknown',
                    createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString()
                };
            });
        } catch (e) {
            console.error('[Dashboard] Recent activity fetch failed:', e);
        }

        // Chart Data: Last 7 Days (Existing logic)
        const chartDataPoints: any[] = [];
        const chartQueries: Promise<number>[] = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            d.setHours(0, 0, 0, 0);
            const nextD = new Date(d);
            nextD.setDate(nextD.getDate() + 1);

            chartQueries.push(
                db.collection('bookings')
                    .where('createdAt', '>=', d)
                    .where('createdAt', '<', nextD)
                    .count()
                    .get()
                    .then(snap => snap.data().count)
            );

            chartDataPoints.push({
                date: d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' }),
                count: 0
            });
        }

        const counts = await Promise.all(chartQueries);
        counts.forEach((c, idx) => chartDataPoints[idx].count = c);

        return {
            counters: {
                totalCustomers,
                totalTechnicians,
                bookingsToday: totalBookingsToday,
                revenueToday,
                totalRevenue,
                platformEarnings: platformEarningsTotal,
                technicianPayouts: technicianPayoutsTotal,
                pendingBookings,
                confirmedBookings,
                activeBookings,
                completedBookings,
                cancelledBookings,
                pendingKYC,
                onlineTechnicians: onlineTechs
            },
            recentActivity,
            chartData: chartDataPoints
        };
    } catch (error: any) {
        console.error('[Dashboard] Unexpected error:', error);
        if (error instanceof functions.https.HttpsError) throw error;
        throw new functions.https.HttpsError('internal', 'Failed to fetch dashboard stats');
    }
  })
);
