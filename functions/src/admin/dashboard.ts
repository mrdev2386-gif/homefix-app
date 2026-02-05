
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { db } from '../shared/config';
import { assertAdmin } from './utils';

export const getDashboardStats = functions.https.onCall(async (data, context) => {
    try {
        await assertAdmin(context);

        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayStr = today.toISOString();

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

        // Revenue calculations
        let revenueToday = 0;
        let totalRevenue = 0;

        try {
            const revenueTodaySnap = await db.collection('bookings')
                .where('paymentStatus', '==', 'paid')
                .where('createdAt', '>=', today) // This requires an index
                .get();

            if (!revenueTodaySnap.empty) {
                revenueTodaySnap.forEach(doc => {
                    const amount = Number(doc.data().finalAmount);
                    if (!isNaN(amount)) revenueToday += amount;
                });
            }

            const totalRevenueSnap = await db.collection('bookings')
                .where('paymentStatus', '==', 'paid') // This might be large, consider aggregation later
                .get();

            if (!totalRevenueSnap.empty) {
                totalRevenueSnap.forEach(doc => {
                    const amount = Number(doc.data().finalAmount);
                    if (!isNaN(amount)) totalRevenue += amount;
                });
            }
        } catch (e) {
            console.error('Failed to calculate revenue:', e);
            // Default to 0
        }

        // Get recent bookings safely
        let recentActivity: any[] = [];
        try {
            const recentSnap = await db.collection('bookings')
                .orderBy('createdAt', 'desc')
                .limit(10)
                .get();

            if (!recentSnap.empty) {
                recentActivity = recentSnap.docs.map(d => {
                    const data = d.data();
                    // Ensure createdAt is a string
                    let createdStr = todayStr;
                    if (data.createdAt && typeof data.createdAt.toDate === 'function') {
                        createdStr = data.createdAt.toDate().toISOString();
                    } else if (data.createdAt && typeof data.createdAt === 'string') {
                        createdStr = data.createdAt;
                    }

                    return {
                        id: d.id,
                        customerName: data.customerName || 'Unknown Customer',
                        serviceTitle: data.serviceTitle || 'Unknown Service',
                        amount: data.finalAmount || 0,
                        status: data.status || 'unknown',
                        createdAt: createdStr
                    };
                });
            }
        } catch (e) {
            console.error('[Dashboard] Failed to fetch recent activity', e);
        }

        // Chart Data: Last 7 Days Bookings
        const chartDataPoints: any[] = [];
        const chartQueries: Promise<number>[] = [];
        const daysToCheck = 7;

        for (let i = daysToCheck - 1; i >= 0; i--) {
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
                    .catch(() => 0)
            );

            chartDataPoints.push({
                date: d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' }),
                fullDate: d.toISOString(),
                count: 0 // Placeholder, will be filled
            });
        }

        const chartCounts = await Promise.all(chartQueries);
        chartCounts.forEach((count, index) => {
            chartDataPoints[index].count = count;
        });

        return {
            counters: {
                totalCustomers,
                totalTechnicians,
                bookingsToday: totalBookingsToday,
                revenueToday,
                totalRevenue,
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
});
