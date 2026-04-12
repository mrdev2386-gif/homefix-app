"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDashboardStats = void 0;
const functions = __importStar(require("firebase-functions"));
const config_1 = require("../shared/config");
const utils_1 = require("./utils");
const security_1 = require("../shared/security");
exports.getDashboardStats = functions.region('asia-south1').https.onCall((0, security_1.secureCallable)(async (data, context) => {
    try {
        await (0, utils_1.assertAdmin)(context);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        // const todayStr = today.toISOString();
        console.log('[Dashboard] Fetching stats...');
        // Helper to safely execute count queries
        const safeCount = async (query) => {
            try {
                const snapshot = await query.count().get();
                return snapshot.data().count || 0;
            }
            catch (e) {
                console.error('Failed to get count:', e);
                return 0; // Default to zero on error
            }
        };
        // Perform queries in parallel
        const [totalCustomers, totalTechnicians, totalBookingsToday, pendingBookings, confirmedBookings, activeBookings, completedBookings, cancelledBookings, pendingKYC, onlineTechs] = await Promise.all([
            safeCount(config_1.db.collection('customers')),
            safeCount(config_1.db.collection('technicians')),
            safeCount(config_1.db.collection('bookings').where('createdAt', '>=', today)),
            safeCount(config_1.db.collection('bookings').where('bookingStatus', '==', 'pending_payment')),
            safeCount(config_1.db.collection('bookings').where('bookingStatus', '==', 'confirmed')),
            safeCount(config_1.db.collection('bookings').where('bookingStatus', 'in', ['assigned', 'on_the_way', 'started'])),
            safeCount(config_1.db.collection('bookings').where('bookingStatus', '==', 'completed')),
            safeCount(config_1.db.collection('bookings').where('bookingStatus', '==', 'cancelled')),
            safeCount(config_1.db.collection('technicians').where('status', '==', 'pending')),
            safeCount(config_1.db.collection('technicians').where('isAvailable', '==', true))
        ]);
        // Revenue & Payout calculations
        let revenueToday = 0;
        let totalRevenue = 0;
        let platformEarningsTotal = 0;
        let technicianPayoutsTotal = 0;
        try {
            const revenueTodaySnap = await config_1.db.collection('bookings')
                .where('paymentStatus', '==', 'paid')
                .where('createdAt', '>=', today)
                .get();
            revenueTodaySnap.forEach(doc => {
                const amount = Number(doc.data().finalAmount || doc.data().price || 0);
                revenueToday += amount;
            });
            // Aggregate Platform Earnings and Payouts
            const paidBookingsSnap = await config_1.db.collection('bookings')
                .where('paymentStatus', '==', 'paid')
                .get();
            paidBookingsSnap.forEach(doc => {
                const data = doc.data();
                const amount = Number(data.finalAmount || data.price || 0);
                totalRevenue += amount;
                platformEarningsTotal += Number(data.platformCommission || (amount * 0.10));
                technicianPayoutsTotal += Number(data.technicianPayout || (amount * 0.90));
            });
        }
        catch (e) {
            console.error('Failed to calculate revenue:', e);
        }
        // Get recent bookings safely
        let recentActivity = [];
        try {
            const recentSnap = await config_1.db.collection('bookings')
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
                    status: data.bookingStatus || 'unknown',
                    createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString()
                };
            });
        }
        catch (e) {
            console.error('[Dashboard] Recent activity fetch failed:', e);
        }
        // Chart Data: Last 7 Days (Existing logic)
        const chartDataPoints = [];
        const chartQueries = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            d.setHours(0, 0, 0, 0);
            const nextD = new Date(d);
            nextD.setDate(nextD.getDate() + 1);
            chartQueries.push(config_1.db.collection('bookings')
                .where('createdAt', '>=', d)
                .where('createdAt', '<', nextD)
                .count()
                .get()
                .then(snap => snap.data().count));
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
    }
    catch (error) {
        console.error('[Dashboard] Unexpected error:', error);
        if (error instanceof functions.https.HttpsError)
            throw error;
        throw new functions.https.HttpsError('internal', 'Failed to fetch dashboard stats');
    }
}));
//# sourceMappingURL=dashboard.js.map